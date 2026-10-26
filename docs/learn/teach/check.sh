#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Learn check: runs every lesson example and compares its output with the recorded output.txt,
# checks every card against its example, its page and the pinned sources, and refuses dashes.
# Usage: SRC=<dir of clones at the commits in PINS> sh docs/learn/teach/check.sh
# Clone the pins first with: sh docs/learn/teach/check.sh clone <dir>
# Verdict line: LEARN-CHECK PASS|FAIL cards=N examples=N fail=N not_run=N. Exit 0 only on PASS.
# Host-only: no example opens a GPU device. jq is used as a read-only JSON checker.
set -u
here=$(cd "$(dirname "$0")" && pwd)

if [ "${1:-}" = clone ]; then
    dest=${2:?clone needs a directory}
    mkdir -p "$dest" || exit 2
    while read -r owner repo sha; do
        case "$owner" in ''|'#'*) continue ;; esac
        if [ ! -d "$dest/$repo/.git" ]; then
            git clone --quiet --filter=blob:none "https://github.com/$owner/$repo.git" "$dest/$repo" || exit 2
        fi
        git -C "$dest/$repo" checkout --quiet "$sha" || exit 2
    done < "$here/PINS"
    exit 0
fi

SRC=${SRC:?set SRC to the directory holding the pinned clones}
OMC=${OMC:-$SRC/omega-mv/seed/out/omc}
export SRC OMC
fail=0
notrun=0
cards=0
examples=0
bad() { printf 'FAIL %s\n' "$*"; fail=$((fail + 1)); }

# Pinned clones present at the right commits.
while read -r owner repo sha; do
    case "$owner" in ''|'#'*) continue ;; esac
    got=$(git -C "$SRC/$repo" rev-parse HEAD 2>/dev/null || echo missing)
    if [ "$got" != "$sha" ]; then
        printf 'NOT_RUN clone %s at %s (have %s)\n' "$repo" "$sha" "$got"
        notrun=$((notrun + 1))
    fi
done < "$here/PINS"

# No em or en dashes in any learn file.
if grep -rlI "$(printf '\342\200\224')\|$(printf '\342\200\223')" "$here" > /dev/null; then
    for f in $(grep -rlI "$(printf '\342\200\224')\|$(printf '\342\200\223')" "$here"); do
        bad "dash in ${f#"$here"/}"
    done
fi

# Every example reproduces its recorded output byte for byte.
for d in "$here"/examples/*/; do
    id=$(basename "$d")
    examples=$((examples + 1))
    if [ ! -f "$d/run.sh" ] || [ ! -f "$d/output.txt" ]; then
        bad "example $id: run.sh or output.txt missing"
        continue
    fi
    out=$(mktemp) || exit 2
    sh "$d/run.sh" > "$out" 2>&1
    rc=$?
    if cmp -s "$out" "$d/output.txt"; then
        printf 'PASS example %s (run.sh rc=%s)\n' "$id" "$rc"
    else
        bad "example $id: output differs (run.sh rc=$rc)"
        diff "$d/output.txt" "$out" | sed -n '1,20p'
    fi
    rm -f "$out"
done

# Cards: required keys, example output equals output.txt, page exists, pinned links resolve.
keys='id track lesson title keywords summary goal key_steps example common_mistake links evidence_level evidence_note page'
for c in "$here"/cards/*.json; do
    cards=$((cards + 1))
    n=$(basename "$c" .json)
    for k in $keys; do
        jq -e "has(\"$k\")" "$c" > /dev/null 2>&1 || bad "card $n: key $k missing"
    done
    [ "$(jq -r .id "$c")" = "$n" ] || bad "card $n: id differs from file name"
    case "$(jq -r .evidence_level "$c")" in
        PROPOSED|IMPLEMENTED|EXERCISED|QUALIFIED) ;;
        *) bad "card $n: evidence_level not one of the four words" ;;
    esac
    page=$(jq -r .page "$c")
    [ -f "$here/$page" ] || bad "card $n: page $page missing"
    if [ -f "$here/examples/$n/output.txt" ]; then
        jq -j .example.output "$c" | cmp -s - "$here/examples/$n/output.txt" ||
            bad "card $n: example.output differs from examples/$n/output.txt"
    else
        bad "card $n: examples/$n/output.txt missing"
    fi
done

# index.json lists exactly the cards, in file order.
ls "$here"/cards/*.json | sed 's|.*/||; s|\.json$||' > "${TMPDIR:-/tmp}/learn-ids.$$"
jq -r '.cards[].id' "$here/index.json" | cmp -s - "${TMPDIR:-/tmp}/learn-ids.$$" ||
    bad "index.json does not list exactly the cards"
rm -f "${TMPDIR:-/tmp}/learn-ids.$$"

# Relative links between lesson pages resolve.
for p in "$here"/pages/*.md; do
    for l in $(grep -o '](\([A-Za-z0-9_.-]*\.md\))' "$p" | sed 's/^](//; s/)$//'); do
        [ -f "$here/pages/$l" ] || bad "page $(basename "$p"): link $l missing"
    done
done

# Every pinned GitHub link in cards, pages and Q&A names a pinned commit and an existing path.
grep -rhoI 'https://github.com/[A-Za-z0-9_.-]*/[A-Za-z0-9_.-]*/\(blob\|tree\)/[0-9a-f]\{40\}/[^ )>"#`]*' \
    "$here/cards" "$here/pages" "$here/qa" | sort -u > "${TMPDIR:-/tmp}/learn-links.$$"
while read -r url; do
    rest=${url#https://github.com/}
    owner=${rest%%/*}; rest=${rest#*/}
    repo=${rest%%/*}; rest=${rest#*/}
    rest=${rest#*/}
    sha=${rest%%/*}; path=${rest#*/}
    path=${path%/}
    pin=$(awk -v o="$owner" -v r="$repo" '$1 == o && $2 == r { print $3 }' "$here/PINS")
    if [ "$pin" != "$sha" ]; then
        bad "link not at a pinned commit: $url"
    elif [ ! -e "$SRC/$repo/$path" ]; then
        bad "link path missing at pin: $url"
    fi
done < "${TMPDIR:-/tmp}/learn-links.$$"
rm -f "${TMPDIR:-/tmp}/learn-links.$$"

if [ "$fail" -eq 0 ] && [ "$notrun" -eq 0 ]; then verdict=PASS; else verdict=FAIL; fi
printf 'LEARN-CHECK %s cards=%s examples=%s fail=%s not_run=%s\n' "$verdict" "$cards" "$examples" "$fail" "$notrun"
[ "$verdict" = PASS ]
