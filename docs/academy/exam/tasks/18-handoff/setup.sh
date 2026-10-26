# setup.sh WS: build the half done csvtool repository with fixed identity and dates
REPO=$(cd "$(dirname "$0")" && pwd)/repo
. "$(dirname "$0")/../../lib.sh"
command -v git > /dev/null 2>&1 || { echo "git is not installed" >&2; exit 1; }
mktmp G
git_env "$G"
cd "$1" || exit 1
git -c init.defaultBranch=main init -q . || exit 1
cp "$REPO/TODO.md" TODO.md
mkdir -p tests
cp "$REPO/run.sh" tests/run.sh
sed '/^# validate LINE N/,$d' "$REPO/csvtool.sh" > csvtool.sh
git add TODO.md tests/run.sh csvtool.sh
git commit -q -m "step 1: parse" || exit 1
cp "$REPO/csvtool.sh" csvtool.sh
git add csvtool.sh
GIT_AUTHOR_DATE="2026-10-22T15:10:00+0000" GIT_COMMITTER_DATE="2026-10-22T15:10:00+0000" \
	git commit -q -m "step 2: validate" || exit 1
