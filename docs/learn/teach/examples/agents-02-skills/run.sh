#!/bin/sh
# agents-02-skills: check the frontmatter of every real omega-harness skill at the pin, then three
# malformed skills (negative controls), then show why a symlink install follows a pull and a copy
# does not. Host-only: sh, grep, sed, awk and git, no GPU, no network.
here=$(cd "$(dirname "$0")" && pwd)
SRC=${SRC:?set SRC to a directory holding the clones in docs/learn/teach/PINS}
H=$SRC/omega-harness
printf 'omega-harness at %s\n' "$(git -C "$H" rev-parse HEAD)"
LC_ALL=C
export LC_ALL
work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
bad=0
expect() {
    sh "$here/check-skill.sh" "$1"
    rc=$?
    printf '  rc=%s (expected %s)\n' "$rc" "$2"
    if [ "$rc" -ne "$2" ]; then
        bad=$((bad + 1))
    fi
}

printf '\n== real skills\n'
for d in "$H"/skills/*/; do
    expect "${d%/}" 0
done

printf '\n== negative controls\n'
mkdir -p "$work/neg/wrong-name" "$work/neg/no-when" "$work/neg/no-frontmatter"
printf -- '---\nname: right-name\ndescription: Checks things. Use before checking things.\n---\nbody\n' > "$work/neg/wrong-name/SKILL.md"
printf -- '---\nname: no-when\ndescription: A collection of useful notes.\n---\nbody\n' > "$work/neg/no-when/SKILL.md"
printf '# no-frontmatter\nUse it whenever.\n' > "$work/neg/no-frontmatter/SKILL.md"
for d in wrong-name no-when no-frontmatter; do
    expect "$work/neg/$d" 1
done

printf '\n== install: symlink follows a pull, a copy goes stale\n'
HOME=$work/home
GIT_CONFIG_NOSYSTEM=1
GIT_CONFIG_GLOBAL=/dev/null
GIT_AUTHOR_NAME=Lane GIT_AUTHOR_EMAIL=lane@example.invalid
GIT_COMMITTER_NAME=Lane GIT_COMMITTER_EMAIL=lane@example.invalid
GIT_AUTHOR_DATE='2026-10-26T00:00:00Z' GIT_COMMITTER_DATE='2026-10-26T00:00:00Z'
export HOME GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
export GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_AUTHOR_DATE GIT_COMMITTER_DATE
mkdir -p "$HOME" "$work/agent-skills" "$work/copied-skills"
up=$work/upstream
git init -q -b main "$up" || exit 2
mkdir -p "$up/skills/demo-skill"
printf -- '---\nname: demo-skill\ndescription: Demo. Use before demos. Pin v1.\n---\n' > "$up/skills/demo-skill/SKILL.md"
git -C "$up" add -A && git -C "$up" commit -q -m v1 || exit 2
git clone -q "$up" "$work/clone" || exit 2
ln -s "$work/clone/skills/demo-skill" "$work/agent-skills/demo-skill"
cp -R "$work/clone/skills/demo-skill" "$work/copied-skills/demo-skill"
printf 'upstream fixes the skill (pin v2)\n'
sed 's/Pin v1/Pin v2/' "$up/skills/demo-skill/SKILL.md" > "$work/t" && cat "$work/t" > "$up/skills/demo-skill/SKILL.md"
git -C "$up" commit -q -am v2 || exit 2
git -C "$work/clone" pull -q --ff-only
printf 'git pull rc=%s\n' "$?"
printf 'symlinked install reads: %s\n' "$(grep -o 'Pin v[0-9]' "$work/agent-skills/demo-skill/SKILL.md")"
printf 'copied install reads:    %s\n' "$(grep -o 'Pin v[0-9]' "$work/copied-skills/demo-skill/SKILL.md")"
expect "$work/agent-skills/demo-skill" 0

printf '\n'
if [ "$bad" -eq 0 ]; then
    printf 'ALL EXIT STATUSES AS EXPECTED\n'
    exit 0
fi
printf 'STATUS MISMATCH count=%s\n' "$bad"
exit 1
