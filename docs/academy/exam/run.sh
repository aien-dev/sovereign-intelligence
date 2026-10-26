#!/bin/sh
# run.sh: build the Agent Academy exam workspaces, then grade them.
#   sh exam/run.sh setup DIR   build DIR/<task>/ from the fixtures and write DIR/PROMPTS.md
#   sh exam/run.sh grade DIR   check every workspace and print the ACADEMY-RESULT block
# POSIX sh, coreutils, git, grep, sed and awk only. No network.
EXAM=$(cd "$(dirname "$0")" && pwd)
. "$EXAM/lib.sh"

usage() { echo "usage: sh run.sh setup DIR | sh run.sh grade DIR" >&2; exit 64; }
[ $# -eq 2 ] || usage
cmd=$1
dir=$2

setup() {
	mkdir -p "$dir" || exit 1
	abs=$(cd "$dir" && pwd) || exit 1
	for t in "$EXAM"/tasks/*/; do
		id=$(basename "$t")
		if [ -e "$abs/$id" ]; then
			echo "run.sh: $abs/$id already exists; use an empty DIR" >&2
			exit 1
		fi
	done
	{
		echo "# Agent Academy exam prompts"
		echo
		echo "Give each task below to your coding agent, one at a time or all at once."
		echo "Paste the text under a task heading as it is. Each task works only in its own folder."
		echo "When the agent is done, grade with: sh $EXAM/run.sh grade $abs"
	} > "$abs/PROMPTS.md"
	for t in "$EXAM"/tasks/*/; do
		t=${t%/}
		id=$(basename "$t")
		build_ws "$t" "$abs/$id" || echo "run.sh: setup of $id failed (see above)" >&2
		{
			echo
			echo "## Task $id"
			echo
			echo "Work only inside this folder: $abs/$id"
			echo
			cat "$t/TASK.md"
		} >> "$abs/PROMPTS.md"
	done
	echo "setup done: $abs (prompts in $abs/PROMPTS.md)"
}

grade() {
	abs=$(cd "$dir" && pwd) || exit 1
	np=0 nf=0 nn=0 n=0
	echo "ACADEMY-RESULT v1 exam=$(exam_id "$EXAM")"
	for t in "$EXAM"/tasks/*/; do
		t=${t%/}
		id=$(basename "$t")
		line=$(sh "$t/check.sh" "$abs/$id" 2>/dev/null | sed -n 1p)
		case $line in
		"$id PASS "*) np=$((np + 1)) ;;
		"$id FAIL "*) nf=$((nf + 1)) ;;
		"$id NOT_RUN "*) nn=$((nn + 1)) ;;
		*) line="$id FAIL grader printed no valid line"; nf=$((nf + 1)) ;;
		esac
		n=$((n + 1))
		printf '%s\n' "$line"
	done
	echo "SCORE pass=$np fail=$nf not_run=$nn total=$n"
}

case $cmd in
setup) setup ;;
grade) grade ;;
*) usage ;;
esac
