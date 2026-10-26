# setup.sh WS: build a git repository with a teammate's uncommitted work plus some junk
REPO=$(cd "$(dirname "$0")" && pwd)/repo
. "$(dirname "$0")/../../lib.sh"
command -v git > /dev/null 2>&1 || { echo "git is not installed" >&2; exit 1; }
mktmp G
git_env "$G"
cd "$1" || exit 1
git -c init.defaultBranch=main init -q . || exit 1
cp "$REPO/pricing.sh" pricing.sh
cp "$REPO/README.md" README.md
git add pricing.sh README.md
git commit -q -m "pricing: base prices" || exit 1
cp "$REPO/app.sh" app.sh
git add app.sh
GIT_AUTHOR_DATE="2026-10-21T09:30:00+0000" GIT_COMMITTER_DATE="2026-10-21T09:30:00+0000" \
	git commit -q -m "app: print totals" || exit 1
cp "$REPO/pricing.wip" pricing.sh
cp "$REPO/SAM-WIP-NOTE.txt" SAM-WIP-NOTE.txt
mkdir -p build
printf 'objfile\n' > build/app.o
printf 'cache\n' > build/cache.tmp
printf 'debug: total=3700\ndebug: total=1200\n' > debug.log
