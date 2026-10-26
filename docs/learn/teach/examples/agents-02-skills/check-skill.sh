#!/bin/sh
# check-skill.sh SKILL_DIR: check the Agent Skills frontmatter of SKILL_DIR/SKILL.md.
# Rules: line 1 is ---, a closing --- follows, name equals the directory name, and description
# is present and says when to use the skill (contains "Use "). Exit 0 PASS, 1 FAIL, 2 usage.
dir=${1:?usage: check-skill.sh SKILL_DIR}
skill=$(basename "$dir")
f=$dir/SKILL.md
fail() { printf 'FAIL %s: %s\n' "$skill" "$1"; exit 1; }
[ -f "$f" ] || fail 'no SKILL.md'
[ "$(sed -n 1p "$f")" = '---' ] || fail 'line 1 is not ---'
end=$(awk 'NR > 1 && $0 == "---" { print NR; exit }' "$f")
[ -n "$end" ] || fail 'frontmatter is never closed'
front=$(sed -n "2,$((end - 1))p" "$f")
name=$(printf '%s\n' "$front" | sed -n 's/^name: *//p')
desc=$(printf '%s\n' "$front" | sed -n 's/^description: *//p')
[ -n "$name" ] || fail 'no name'
[ "$name" = "$skill" ] || fail "name '$name' differs from directory '$skill'"
[ -n "$desc" ] || fail 'no description'
printf '%s\n' "$desc" | grep -q 'Use ' || fail 'description never says when to use it'
printf 'PASS %s: name ok, description %s bytes, body %s lines\n' "$skill" "$(printf '%s' "$desc" | wc -c | tr -d ' ')" "$(($(wc -l < "$f") - end))"
