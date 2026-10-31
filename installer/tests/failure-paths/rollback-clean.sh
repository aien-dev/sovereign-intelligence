#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Failure path: `aienos rollback` and `aienos uninstall` leave nothing outside
# ~/.local/share/aienos.
#
# Preconditions: OMC = the pinned omc; python3, openssl, curl, tar. Host run in scratch homes on a
#   fake GB10 probe root, with XDG_CONFIG_HOME, XDG_DATA_HOME, XDG_CACHE_HOME and XDG_STATE_HOME
#   at their defaults under HOME, XDG_RUNTIME_DIR and TMPDIR in their own scratch folders. Two
#   homes: "bare" (only Desktop) and "used" (Desktop plus a user's own files and the usual
#   .config, .cache, .local/bin, .local/share/applications, .local/share/icons and .local/state,
#   some of them empty). In each: install the older release alpha-20261025.9, run the wizard
#   (model download, engine start), stop the engine, install this release, `aienos rollback`;
#   then "bare" runs `aienos uninstall --yes` and "used" `aienos uninstall --keep-model --yes`.
#   Every path (files, links and folders) under HOME, XDG_RUNTIME_DIR and TMPDIR is listed before
#   the first install, before the rollback, after the rollback and after the uninstall.
# Expected result: the rollback points current at the older release and adds no path outside
#   ~/.local/share/aienos; after the uninstall the paths outside ~/.local/share/aienos are exactly
#   those before the first install (nothing new, nothing of the user's removed), and
#   ~/.local/share/aienos is gone ("bare") or holds only the model ("used").
# Negative control: the same checker after `aienos rollback` and `aienos uninstall --yes` of a
#   test release whose uninstaller skips its folder sweep (FP_MUTATE) must find the folders the
#   install made (opposite verdict).
# Not counted: ~/.local/share/gvfs-metadata (GNOME's metadata database, written by `gio set` for
#   the desktop icon's "trusted" flag); its paths are listed in the log. Stock Spark: NOT_RUN.
#
# usage: OMC=... sh rollback-clean.sh [SCRATCH]
set -u
FP_NAME=rollback-clean
S=${1:-$(mktemp -d "${TMPDIR:-/tmp}/aienos-fp-rollback.XXXXXX")}
. "$(dirname "$0")/lib.sh"
fp_require
fp_serve
port=$(fp_port)
OLD=alpha-20261025.9
fp_compile "$S/bin" "$port" || fp_notrun "omc refused the test wizard ($S/bin/omc.err)"
FP_TAG=$OLD fp_release old "$S/bin"
fp_release new "$S/bin"
R=$(fp_root gb10)
ALL='\n\n\nyes\n\n\n\n\n\n\n'
G=gvfs-metadata

# snap HOME: every path outside ~/.local/share/aienos under HOME, XDG_RUNTIME_DIR and TMPDIR,
# with the roots written as $HOME, $XDG_RUNTIME_DIR, $TMPDIR (gvfs metadata to $S/gvfs-*).
snap() {
    b=$1/.local/share/aienos
    (cd "$1" && find . -mindepth 1 \( -path ./.local/share/aienos -prune -o -path "./.local/share/$G" -prune \) \
        -o -print | sed 's|^\.|$HOME|')
    (cd "$S/run-${1##*/home-}" && find . -mindepth 1 | sed 's|^\.|$XDG_RUNTIME_DIR|')
    (cd "$S/tmp-${1##*/home-}" && find . -mindepth 1 | sed 's|^\.|$TMPDIR|')
}
# run HOME CMD...: CMD with the scratch environment of HOME.
run() {
    h=$1; shift
    env HOME="$h" AIENOS_PROBE_ROOT="$R" TMPDIR="$S/tmp-${h##*/home-}" \
        XDG_RUNTIME_DIR="$S/run-${h##*/home-}" "$@"
}
newhome() {
    h=$(fp_home "$1")
    rm -rf "$S/run-$1" "$S/tmp-$1"; mkdir -p "$S/run-$1" "$S/tmp-$1"
    chmod 700 "$S/run-$1"
    printf '%s' "$h"
}
# installrel HOME RELEASE: install.sh of www/RELEASE, as "curl ... | sh" runs it.
installrel() {
    run "$1" env AIENOS_BASE_URL="http://127.0.0.1:$FP_HTTP/$2" AIENOS_NO_WIZARD=1 \
        sh "$S/www/$2/install.sh"
}
# diffpaths A B: the paths in B that are not in A.
newpaths() { LC_ALL=C sort "$1" > "$1.s"; LC_ALL=C sort "$2" > "$2.s"; LC_ALL=C comm -13 "$1.s" "$2.s"; }

# lifecycle NAME UNINSTALL-ARGS: one home through install, wizard, update, rollback, uninstall.
# Sets ROLLED, LEFT (new paths after the uninstall) and LOST (user paths gone).
lifecycle() {
    k=$1; u=$2; h=$S/home-$k
    snap "$h" > "$S/$k.0"
    installrel "$h" old > "$S/$k.install-old.out" 2>&1
    check "$k: older release $OLD installs (exit $?)" $?
    printf '%b' "$ALL" | run "$h" timeout 300 "$h/.local/share/aienos/current/bin/aienos" wizard --plain \
        > "$S/$k.wizard.out" 2>&1
    check "$k: wizard ran to the end (exit $?)" $?
    run "$h" "$h/.local/share/aienos/current/bin/aienos" stop > "$S/$k.stop.out" 2>&1
    check "$k: the model is verified" "$([ -f "$h/.local/share/aienos/models/test-model/.aienos-verified" ]; echo $?)"
    installrel "$h" new > "$S/$k.install-new.out" 2>&1
    check "$k: this release ($TAG) installs over it (exit $?)" $?
    snap "$h" > "$S/$k.1"
    run "$h" "$h/.local/share/aienos/current/bin/aienos" rollback > "$S/$k.rollback.out" 2>&1; rc=$?
    ROLLED=no
    [ $rc -eq 0 ] && [ "$(readlink "$h/.local/share/aienos/current")" = "releases/$OLD" ] && ROLLED=yes
    snap "$h" > "$S/$k.2"
    run "$h" "$h/.local/share/aienos/current/bin/aienos" uninstall $u > "$S/$k.uninstall.out" 2>&1
    URC=$?
    snap "$h" > "$S/$k.3"
    RNEW=$(newpaths "$S/$k.1" "$S/$k.2")
    LEFT=$(newpaths "$S/$k.0" "$S/$k.3")
    LOST=$(newpaths "$S/$k.3" "$S/$k.0")
    if [ -d "$h/.local/share/$G" ]; then
        (cd "$h/.local/share" && find "$G" | sed 's/^/      not counted: ~\/.local\/share\//')
    fi
}
# report NAME: the checks on lifecycle's results.
report() {
    check "$1: rollback exit 0, current -> releases/$OLD: $ROLLED" "$([ $ROLLED = yes ]; echo $?)"
    printf '%s\n' "$RNEW" | sed '/^$/d; s/^/      new after rollback: /'
    check "$1: rollback added no path outside ~/.local/share/aienos" "$([ -z "$RNEW" ]; echo $?)"
    check "$1: uninstall exit 0 (got $URC)" "$([ $URC -eq 0 ]; echo $?)"
    printf '%s\n' "$LEFT" | sed '/^$/d; s/^/      left after uninstall: /'
    check "$1: after uninstall no new path outside ~/.local/share/aienos" "$([ -z "$LEFT" ]; echo $?)"
    printf '%s\n' "$LOST" | sed '/^$/d; s/^/      lost: /'
    check "$1: nothing of the user's was removed" "$([ -z "$LOST" ]; echo $?)"
}

h=$(newhome bare)
lifecycle bare --yes
report bare
check "bare: ~/.local/share/aienos is gone" "$([ ! -e "$h/.local/share/aienos" ]; echo $?)"

h=$(newhome used)
mkdir -p "$h/.config/someapp" "$h/.cache/someapp" "$h/.local/bin" "$h/.local/share/applications" \
    "$h/.local/share/icons" "$h/.local/state" "$h/Documents"
printf 'x=1\n' > "$h/.config/someapp/someapp.conf"
printf '#!/bin/sh\n' > "$h/.local/bin/myscript"
printf '[Desktop Entry]\nName=Other\n' > "$h/.local/share/applications/other.desktop"
printf 'notes\n' > "$h/Documents/notes.txt"
lifecycle used "--keep-model --yes"
report used
m=$h/.local/share/aienos
[ -f "$m/models/test-model/weights.bin" ] && [ -z "$(cd "$m" && find . -mindepth 1 ! -path './models' ! -path './models/*')" ]
check "used: ~/.local/share/aienos holds only the kept model" $?

# Negative control: a release whose uninstaller skips the folder sweep (ulsweep), bare home.
FP_MUTATE='s/^ulsweep$/note ulsweep skipped/' fp_compile "$S/bin-mut" "$port" \
    || fp_notrun "omc refused the no-sweep test wizard ($S/bin-mut/omc.err)"
FP_TAG=$OLD fp_release old "$S/bin-mut"
fp_release new "$S/bin-mut"
bad=$FP_BAD
h=$(newhome mut)
lifecycle mut --yes
FP_BAD=$bad
printf '%s\n' "$LEFT" | sed '/^$/d; s/^/      control left after uninstall: /'
ctl=same
[ -n "$LEFT" ] && ctl=opposite
check "negative control (uninstaller without its folder sweep leaves paths): $ctl" "$([ $ctl = opposite ]; echo $?)"
fp_result "EXERCISED(host, fake GB10 root) cases=bare,used control=$ctl spark=NOT_RUN"
