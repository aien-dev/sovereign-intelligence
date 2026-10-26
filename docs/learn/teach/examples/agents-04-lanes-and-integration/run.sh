#!/bin/sh
# agents-04-lanes-and-integration: parallel lanes in their own git worktrees, one integration owner.
# 1. Lanes A and B each commit in their own worktree; B also leaves an uncommitted edit.
# 2. The integration owner merges committed branches only and never touches B's dirty tree.
# 3. Lanes C and D both edit the same line of a shared file; the owner merges C, detects the
#    conflict on D, aborts, and sends D back to rebase in its own worktree.
# Host-only: git is the subject here, no GPU, no network. Statuses are printed, never hidden.
work=$(mktemp -d) || exit 2
trap 'rm -rf "$work"' EXIT
HOME=$work/home
GIT_CONFIG_NOSYSTEM=1
GIT_CONFIG_GLOBAL=/dev/null
GIT_AUTHOR_NAME=Lane GIT_AUTHOR_EMAIL=lane@example.invalid
GIT_COMMITTER_NAME=Lane GIT_COMMITTER_EMAIL=lane@example.invalid
GIT_AUTHOR_DATE='2026-10-26T00:00:00Z' GIT_COMMITTER_DATE='2026-10-26T00:00:00Z'
export HOME GIT_CONFIG_NOSYSTEM GIT_CONFIG_GLOBAL GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
GIT_EDITOR=true
export GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL GIT_AUTHOR_DATE GIT_COMMITTER_DATE GIT_EDITOR
mkdir -p "$HOME" || exit 2
main=$work/main
q() { "$@" > "$work/log" 2>&1; }

git init -q -b main "$main" || exit 2
printf 'owner: integration\nversion: 1\n' > "$main/shared.txt"
q git -C "$main" add -A && q git -C "$main" commit -m base || exit 2
for l in a b c d; do
    q git -C "$main" worktree add -b "lane-$l" "$work/lane-$l" main
    printf 'worktree lane-%s rc=%s\n' "$l" "$?"
done

printf '\n== lanes work in parallel, each in its own tree\n'
printf 'parser fix\n' > "$work/lane-a/parser.txt"
q git -C "$work/lane-a" add -A && q git -C "$work/lane-a" commit -m 'lane a: parser'
printf 'lane-a commit rc=%s\n' "$?"
printf 'docs\n' > "$work/lane-b/docs.txt"
q git -C "$work/lane-b" add -A && q git -C "$work/lane-b" commit -m 'lane b: docs'
printf 'lane-b commit rc=%s\n' "$?"
printf 'half-finished idea\n' > "$work/lane-b/wip.txt"
printf 'lane-b leaves an uncommitted file: %s\n' "$(git -C "$work/lane-b" status --porcelain)"

printf '\n== integration owner merges committed branches only\n'
for l in a b; do
    q git -C "$main" merge --no-ff -m "merge lane-$l" "lane-$l"
    printf 'merge lane-%s rc=%s\n' "$l" "$?"
done
printf 'main now has: %s\n' "$(git -C "$main" ls-files | tr '\n' ' ')"
if [ -f "$main/wip.txt" ]; then w=present; else w=absent; fi
printf 'lane-b uncommitted file on main: %s\n' "$w"
printf 'lane-b dirty tree untouched: %s\n' "$(git -C "$work/lane-b" status --porcelain)"

printf '\n== two lanes edit the same line of a shared file\n'
sed 's/version: 1/version: 2 (lane c)/' "$work/lane-c/shared.txt" > "$work/t" && cat "$work/t" > "$work/lane-c/shared.txt"
q git -C "$work/lane-c" commit -am 'lane c: bump version'
printf 'lane-c commit rc=%s\n' "$?"
sed 's/version: 1/version: 3 (lane d)/' "$work/lane-d/shared.txt" > "$work/t" && cat "$work/t" > "$work/lane-d/shared.txt"
q git -C "$work/lane-d" commit -am 'lane d: bump version'
printf 'lane-d commit rc=%s\n' "$?"
q git -C "$main" merge --no-ff -m 'merge lane-c' lane-c
printf 'merge lane-c rc=%s\n' "$?"
q git -C "$main" merge --no-ff -m 'merge lane-d' lane-d
rc=$?
printf 'merge lane-d rc=%s\n' "$rc"
conflicts=$(git -C "$main" diff --name-only --diff-filter=U)
printf 'conflicted files: %s\n' "$conflicts"
if [ "$rc" -ne 0 ]; then
    q git -C "$main" merge --abort
    printf 'owner aborts the merge rc=%s, main is clean: [%s]\n' "$?" "$(git -C "$main" status --porcelain)"
    printf 'CONFLICT: lane-d must rebase onto main in its own worktree and re-decide shared.txt\n'
fi

printf '\n== lane d resolves in its own tree, owner merges again\n'
q git -C "$work/lane-d" rebase main
printf 'lane-d rebase rc=%s (conflict expected)\n' "$?"
printf 'owner: integration\nversion: 3 (lane d, after lane c)\n' > "$work/lane-d/shared.txt"
q git -C "$work/lane-d" add shared.txt && q git -C "$work/lane-d" rebase --continue
printf 'lane-d rebase --continue rc=%s\n' "$?"
q git -C "$main" merge --no-ff -m 'merge lane-d' lane-d
printf 'merge lane-d rc=%s\n' "$?"
printf 'final shared.txt:\n'
cat "$main/shared.txt"
printf 'main history:\n'
git -C "$main" log --format='  %s' --first-parent
