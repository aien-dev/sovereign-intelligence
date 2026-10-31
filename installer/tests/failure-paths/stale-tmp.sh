#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: install.sh is killed with SIGKILL (a power cut) and leaves its temporary folder
# TMPDIR/aienos-install.XXXXXX; the next run must remove it, and nothing else.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar, bwrap (nested: it shows a
#   folder owned by another user, /usr/share/doc, inside TMPDIR). Host run in a scratch home on a
#   fake GB10 probe root, release served from 127.0.0.1. shim.sh (as curl) sends KILL to install.sh
#   once half the bundle is written. An rm shim first on the re-run's PATH logs every rm.
#   Planted in TMPDIR before the re-run:
#     live    aienos-install.live: pid file names a running process          -> kept
#     young   aienos-install.young: no pid file, made now                      -> kept
#     badpid  aienos-install.badpid: pid file "x" (not a number), made now     -> kept
#     old     aienos-install.old: no pid file, mtime two hours ago             -> removed
#     link    aienos-install.link: symlink to a folder with a dead pid file    -> link and target kept
#     other   aienos-install.other: another user's folder (/usr/share/doc), old, no pid -> kept
#     prefix  aienos-installer.1, aienos-fp.1, x-aienos-install.1: dead pid files -> kept
# Expected result: the re-run exits 0 and installs; the killed run's folder and "old" are gone;
#   every other planted path is still there with its contents; rm never named a planted path that
#   must stay, nor anything outside TMPDIR's aienos-install.* names (no link was followed).
# Negative control: the same steps with install.sh's cleanup loop emptied: the killed run's folder
#   stays (opposite verdict).
# Status: EXERCISED(host). A power cut on a stock DGX Spark: NOT_RUN.
#
# usage: OMC=... sh stale-tmp.sh [SCRATCH]
set -u
FP_NAME=stale-tmp
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-tmp.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
command -v bwrap > /dev/null 2>&1 || fp_notrun "bwrap missing"
[ -d /usr/share/doc ] && [ ! -O /usr/share/doc ] || fp_notrun "no folder owned by another user"
fp_serve
fp_compile "$S/bin" "$(fp_port)" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
fp_release good "$S/bin"
# The control build: the same release with the cleanup loop given nothing to walk.
rm -rf "$S/www/nocl"; cp -R "$S/www/good" "$S/www/nocl"
sed 's|^for old in "\${TMPDIR:-/tmp}"/aienos-install\.\*; do$|for old in; do|' \
    "$S/www/good/install.sh" > "$S/www/nocl/install.sh"
cmp -s "$S/www/good/install.sh" "$S/www/nocl/install.sh" && fp_notrun "control build: cleanup loop not found"
mkdir -p "$S/rmshim"
cat > "$S/rmshim/rm" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$S/rm.log"
PATH=\$FP_REALPATH exec rm "\$@"
EOF
chmod +x "$S/rmshim/rm"

# case NAME RELEASE: kill an install of RELEASE, plant, re-run. Sets DEAD (the killed run's folder).
case_run() {
    T=$S/tmp; rm -rf "$T" "$S/victim-$1" "$S/rm.log"; mkdir -p "$T"
    h=$(fp_home "$1")
    FP_KILL=download FP_SIG=KILL fp_boot "$h" "$2" > "$S/$1.kill.out" 2>&1; rc=$?
    check "$1: install.sh killed (exit $rc)" "$([ $rc -ne 0 ]; echo $?)"
    DEAD=$(ls -d "$T"/aienos-install.* 2>/dev/null | head -n 1)
    [ -n "$DEAD" ] && [ -f "$DEAD/pid" ] && ! kill -0 "$(cat "$DEAD/pid")" 2>/dev/null
    check "$1: the killed run left ${DEAD#$S/} with its dead pid" $?
    sleep 600 & live=$!
    mkdir "$T/aienos-install.live"; echo $live > "$T/aienos-install.live/pid"
    mkdir "$T/aienos-install.young"
    mkdir "$T/aienos-install.badpid"; echo x > "$T/aienos-install.badpid/pid"
    mkdir "$T/aienos-install.old"; touch -d '2 hours ago' "$T/aienos-install.old"
    mkdir -p "$S/victim-$1"; echo 999999999 > "$S/victim-$1/pid"; echo keep > "$S/victim-$1/data"
    touch -d '2 hours ago' "$S/victim-$1"
    ln -s "$S/victim-$1" "$T/aienos-install.link"
    mkdir "$T/aienos-install.other"
    for p in aienos-installer.1 aienos-fp.1 x-aienos-install.1; do
        mkdir "$T/$p"; echo 999999999 > "$T/$p/pid"; touch -d '2 hours ago' "$T/$p"
    done
    env HOME="$h" AIENOS_PROBE_ROOT="$(fp_root gb10)" PATH="$S/rmshim:$PATH" FP_REALPATH="$PATH" \
        AIENOS_BASE_URL="http://127.0.0.1:$FP_HTTP/$2" AIENOS_NO_WIZARD=1 TMPDIR="$T" \
        bwrap --dev-bind / / --ro-bind /usr/share/doc "$T/aienos-install.other" \
        sh "$S/www/$2/install.sh" > "$S/$1.rerun.out" 2>&1; RC=$?
    kill $live 2>/dev/null; wait $live 2>/dev/null
    ls -lA "$T" | sed 's/^/      tmp: /'
    [ -e "$S/rm.log" ] && sed 's/^/      rm /' "$S/rm.log"
}

case_run good good
check "good: re-run exit 0 (got $RC)" "$([ $RC -eq 0 ]; echo $?)"
fp_installed "$h"; check "good: re-run gives a complete verified install" $?
[ ! -e "$DEAD" ]; check "good: the killed run's folder ${DEAD#$S/} is gone" $?
[ ! -e "$T/aienos-install.old" ]; check "good: the pid-less folder two hours old is gone" $?
[ -f "$T/aienos-install.live/pid" ]; check "good: a live run's folder is kept" $?
[ -d "$T/aienos-install.young" ]; check "good: a pid-less folder younger than 60 min is kept" $?
[ -f "$T/aienos-install.badpid/pid" ]; check "good: a folder whose pid is not a number (and young) is kept" $?
[ -L "$T/aienos-install.link" ] && [ -f "$S/victim-good/data" ] && [ -f "$S/victim-good/pid" ]
check "good: the planted symlink and its target's files are kept" $?
[ -f "$T/aienos-installer.1/pid" ] && [ -f "$T/aienos-fp.1/pid" ] && [ -f "$T/x-aienos-install.1/pid" ]
check "good: folders outside the aienos-install.* prefix are kept" $?
# The bind of /usr/share/doc exists only inside the re-run's bwrap; out here its mount point
# stays, and the rm log (below) shows whether the re-run tried to remove it.
[ -d "$T/aienos-install.other" ]; check "good: another user's folder is kept (never passed to rm)" $?
! grep -E 'aienos-install\.(live|young|badpid|link|other)|aienos-installer|aienos-fp|x-aienos|victim' "$S/rm.log"
check "good: rm never named a path that must stay" $?
grep -qxF -- "-rf $DEAD" "$S/rm.log"; check "good: rm removed the killed run's folder by name" $?
[ "$(ls -d "$T"/aienos-install.* | wc -l)" -eq 5 ]; check "good: no temp folder of the re-run itself left" $?

# Negative control: no cleanup loop, the killed run's folder stays.
case_run nocl nocl
ctl=same
[ $RC -eq 0 ] && [ -d "$DEAD" ] && ctl=opposite
check "negative control (install.sh without the cleanup keeps ${DEAD#$S/}): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host) cases=kill-rerun,live,young,badpid,old,symlink,other-user,other-prefix control=$ctl spark=NOT_RUN"
