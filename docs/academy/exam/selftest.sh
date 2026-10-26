#!/bin/sh
# selftest.sh: prove every grader. For each task the untouched workspace must not PASS, the
# reference state selftest/good (and any other good*) must PASS and every selftest/bad* state must FAIL. A state is an
# overlay copied over the fixture; an optional _delete file lists paths to remove and an optional
# _apply.sh runs inside the workspace (git identity and dates fixed, HOME in a scratch folder).
# Omega tasks (a requires_omc file) are graded with OMC when it is the pinned omc, and always
# again with OMC unset, where good must print NOT_RUN and no state may PASS.
# Prints ACADEMY-SELFTEST PASS tasks=N when every expectation holds.
EXAM=$(cd "$(dirname "$0")" && pwd)
. "$EXAM/lib.sh"

bad=0
ntask=0
omcskip=0
mktmp ROOT
if omc_ready; then HAVE_OMC=1; else HAVE_OMC=0; fi

# state_ws TASKDIR STATE WS: build WS for STATE (untouched or an overlay folder name)
state_ws() {
	build_ws "$1" "$3" >/dev/null 2>&1 || return 1
	[ "$2" = untouched ] && return 0
	_o=$1/selftest/$2
	cp -R "$_o/." "$3/" || return 1
	rm -f "$3/_delete" "$3/_apply.sh"
	if [ -f "$_o/_delete" ]; then
		while IFS= read -r _p; do
			[ -n "$_p" ] && rm -rf "$3/$_p"
		done < "$_o/_delete"
	fi
	if [ -f "$_o/_apply.sh" ]; then
		mkdir -p "$ROOT/home"
		(cd "$3" && git_env "$ROOT/home" && sh "$_o/_apply.sh") >/dev/null 2>&1 || return 1
	fi
	return 0
}

# expect TASKDIR STATE MODE OMCVALUE: grade one state and compare with the expectation
expect() {
	_id=$(basename "$1")
	_ws=$ROOT/ws.$$.$_n
	_n=$((_n + 1))
	if ! state_ws "$1" "$2" "$_ws"; then
		echo "selftest $_id $2 $3 BUILD_ERROR"
		bad=1
		return
	fi
	_line=$(OMC=$4 sh "$1/check.sh" "$_ws" 2>/dev/null)
	_rc=$?
	_word=$(printf '%s\n' "$_line" | awk 'NR == 1 {print $2}')
	_ok=1
	[ "$(printf '%s\n' "$_line" | wc -l | tr -d ' ')" = 1 ] || _ok=0
	case $_line in "$_id "*" "?*) ;; *) _ok=0 ;; esac
	if printf '%s' "$_line" | LC_ALL=C grep -q '[^ -~]'; then _ok=0; fi
	case $_word:$_rc in PASS:0 | FAIL:1 | NOT_RUN:2) ;; *) _ok=0 ;; esac
	case $3:$2 in
	omc:untouched | plain:untouched | noomc:untouched) _want="FAIL|NOT_RUN" ;;
	noomc:good*) _want=NOT_RUN ;;
	noomc:bad*) _want="FAIL|NOT_RUN" ;;
	*:good*) _want=PASS ;;
	*:bad*) _want=FAIL ;;
	*) _want=NAMING_ERROR ;;
	esac
	case "|$_want|" in *"|$_word|"*) ;; *) _ok=0 ;; esac
	if [ "$_ok" = 1 ]; then
		echo "selftest $2 $3 ok: $_line"
	else
		echo "selftest $_id $2 $3 MISMATCH want $_want got: $_line (exit $_rc)"
		bad=1
	fi
	rm -rf "$_ws"
}

_n=0
for t in "$EXAM"/tasks/*/; do
	t=${t%/}
	ntask=$((ntask + 1))
	states="untouched"
	[ -d "$t/selftest/good" ] || { echo "selftest $(basename "$t") has no selftest/good"; bad=1; }
	nbad=0
	for s in "$t"/selftest/*/; do
		s=$(basename "$s")
		states="$states $s"
		case $s in bad*) nbad=$((nbad + 1)) ;; esac
	done
	[ "$nbad" -ge 1 ] || { echo "selftest $(basename "$t") has no selftest/bad state"; bad=1; }
	if [ -f "$t/requires_omc" ]; then
		if [ "$HAVE_OMC" = 1 ]; then
			for s in $states; do expect "$t" "$s" omc "$OMC"; done
		else
			echo "selftest $(basename "$t") omc NOT_RUN ($OMC_WHY)"
			omcskip=$((omcskip + 1))
		fi
		for s in $states; do expect "$t" "$s" noomc ""; done
	else
		for s in $states; do expect "$t" "$s" plain ""; done
	fi
done

if [ "$bad" != 0 ]; then
	echo "ACADEMY-SELFTEST FAIL tasks=$ntask"
	exit 1
fi
if [ "$omcskip" != 0 ]; then
	echo "ACADEMY-SELFTEST PASS tasks=$ntask omc_not_run=$omcskip"
else
	echo "ACADEMY-SELFTEST PASS tasks=$ntask"
fi
exit 0
