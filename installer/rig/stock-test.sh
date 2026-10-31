#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Host arms of the post-reset stock check (DRA-44). Sequencing only: every judgment is made by
# installer/rig/stock.om. Every root here is FAKE: a directory tree this script writes under
# mktemp, never a DGX Spark, and every result line says so.
#   sh installer/rig/stock-test.sh OMC   (OMC = the pinned omega-mv seed/out/omc; its sha256 is checked)
# Passing arms: the clean fake root passes, chosen by $SI_STOCK_ROOT and by the argument.
# Negative controls: each planted leftover must exit 1 with exactly one deviation, the one named in
# the table below; the clean root must be byte-for-byte unchanged by every run.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
omc=${1:?usage: stock-test.sh OMC}
pin=62775d2a391cfef7cde64e387655caa9809a267093112910ec76bfa568f3712b
echo "$pin  $omc" | sha256sum -c - >/dev/null || { echo "stock-test.sh: $omc is not the pinned omc $pin"; exit 3; }
out=$(mktemp -d)
trap 'chmod -R u+w "$out" 2>/dev/null; rm -rf "$out"' EXIT
"$omc" < "$here/stock.om" > "$out/stock"
chmod +x "$out/stock"
stock=$out/stock
hx() { printf '%04X' "$1"; }

# The clean FAKE root: what the check reads on a stock DGX OS, with stock values.
clean() {
	r=$1
	mkdir -p "$r/etc/systemd/system/multi-user.target.wants" "$r/etc/systemd/user" \
		"$r/usr/lib/systemd/system" "$r/usr/lib/systemd/user" "$r/run/systemd/system" \
		"$r/var/lib/dpkg" "$r/sys/module/nvidia" "$r/proc/net" "$r/proc/1" "$r/proc/812" \
		"$r/root" "$r/home/tester/.config/systemd/user" "$r/home/tester/Schreibtisch" \
		"$r/home/tester/.local/bin" "$r/home/tester/.local/share/applications" \
		"$r/home/tester/.cache/huggingface/hub/models--Qwen--Qwen3-8B"
	echo 'FAKE root written by installer/rig/stock-test.sh; not a DGX Spark.' > "$r/FAKE"
	cat > "$r/etc/passwd" <<-'EOF'
	root:x:0:0:root:/root:/bin/bash
	daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
	nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
	tester:x:1000:1000:Tester,,,:/home/tester:/bin/bash
	EOF
	printf 'DGX_NAME="DGX Spark"\nDGX_SWBUILD_VERSION="7.2.3"\n' > "$r/etc/dgx-release"
	for p in curl openssl coreutils tar gzip sed xdg-user-dirs bash; do
		printf 'Package: %s\nStatus: install ok installed\nArchitecture: arm64\nVersion: 1.0-FAKE\n\n' "$p"
	done > "$r/var/lib/dpkg/status"
	printf 'Package: aienos-old\nStatus: deinstall ok config-files\nVersion: 0.1\n' >> "$r/var/lib/dpkg/status"
	echo 580.173.02 > "$r/sys/module/nvidia/version"
	echo '  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode' > "$r/proc/net/tcp"
	echo '  sl  local_address                         remote_address                        st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode' > "$r/proc/net/tcp6"
	tcp "$r/proc/net/tcp" 22 0A
	tcp "$r/proc/net/tcp" 18100 01
	echo systemd > "$r/proc/1/comm"
	echo sshd > "$r/proc/812/comm"
	touch "$r/etc/systemd/system/multi-user.target.wants/ssh.service" "$r/usr/lib/systemd/system/ssh.service"
	printf 'XDG_DOCUMENTS_DIR="$HOME/Dokumente"\nXDG_DESKTOP_DIR="$HOME/Schreibtisch"\n' > "$r/home/tester/.config/user-dirs.dirs"
	touch "$r/home/tester/.local/share/applications/org.gnome.Terminal.desktop"
}

# tcp FILE PORT ST: one socket row (local port PORT, state ST; 0A is LISTEN, 01 established).
tcp() {
	sl=$(($(wc -l < "$1") - 1))
	case $1 in
	*6) a=00000000000000000000000000000000 ;;
	*) a=00000000 ;;
	esac
	echo "   $sl: $a:$(hx "$2") $a:0000 $3 00000000:00000000 00:00000000 00000000     0        0 4711 1 0000000000000000 100 0 0 10 0" >> "$1"
}

# plant NAME ROOT: put exactly one leftover into ROOT.
plant() {
	r=$2
	h=$r/home/tester
	case $1 in
	si-base) mkdir -p "$h/.local/share/aienos/models" ;;
	si-bin-dangling) ln -s ../share/aienos/current/bin/aienos "$h/.local/bin/aienos" ;;
	si-menu) touch "$h/.local/share/applications/aienos.desktop" ;;
	si-icon) mkdir -p "$h/.local/share/icons/hicolor/scalable/apps" && touch "$h/.local/share/icons/hicolor/scalable/apps/aienos.svg" ;;
	si-desktop) mkdir -p "$h/Desktop" && touch "$h/Desktop/aienos.desktop" ;;
	si-xdg-desktop) touch "$h/Schreibtisch/aienos.desktop" ;;
	si-root-home) mkdir -p "$r/root/.local/share/aienos" ;;
	hf-model) mkdir -p "$h/.cache/huggingface/hub/models--Qwen--Qwen3.6-35B-A3B-FP8/blobs" ;;
	si-clone) mkdir -p "$h/sovereign-intelligence/.git" ;;
	unit-etc) touch "$r/etc/systemd/system/aien-serve.service" ;;
	unit-wants) ln -s /etc/systemd/system/flint-gate.service "$r/etc/systemd/system/multi-user.target.wants/flint-gate.service" ;;
	unit-user) touch "$h/.config/systemd/user/oh-infer-volunteer.service" ;;
	unit-usrlib) touch "$r/usr/lib/systemd/system/aienos-lend.service" ;;
	user) echo 'aien-svc:x:998:998::/var/lib/aien:/usr/sbin/nologin' >> "$r/etc/passwd" ;;
	port-18100) tcp "$r/proc/net/tcp" 18100 0A ;;
	port-18091-tcp6) tcp "$r/proc/net/tcp6" 18091 0A ;;
	port-18300) tcp "$r/proc/net/tcp" 18300 0A ;;
	proc-engine) mkdir "$r/proc/4242" && echo aien-serve-http > "$r/proc/4242/comm" ;;
	proc-lend) mkdir "$r/proc/4343" && echo oh-infer-volunt > "$r/proc/4343/comm" ;;
	proc-wizard) mkdir "$r/proc/4444" && echo aienos > "$r/proc/4444/comm" ;;
	pkg-removed) sed -i '/^Package: curl$/{n;s/.*/Status: deinstall ok config-files/}' "$r/var/lib/dpkg/status" ;;
	pkg-absent) sed -i '/^Package: xdg-user-dirs$/,/^$/d' "$r/var/lib/dpkg/status" ;;
	driver-wrong) echo 580.95.05 > "$r/sys/module/nvidia/version" ;;
	driver-missing) rm "$r/sys/module/nvidia/version" ;;
	no-dgx-release) rm "$r/etc/dgx-release" ;;
	no-root-user) sed -i '/^root:/d' "$r/etc/passwd" ;;
	no-tcp6) rm "$r/proc/net/tcp6" ;;
	dpkg-long-line) head -c 70000 /dev/zero | tr '\0' x >> "$r/var/lib/dpkg/status" ;;
	*) echo "plant: unknown $1"; exit 3 ;;
	esac
}

snap() { (cd "$1" && find . -printf '%p %y %m %s %l\n' | LC_ALL=C sort && find . -type f -exec sha256sum {} + | LC_ALL=C sort) | sha256sum; }

fail=0
c=$out/clean
clean "$c"
before=$(snap "$c")

rc=0
SI_STOCK_ROOT=$c "$stock" > "$out/o" || rc=$?
if [ "$rc" = 0 ] && grep -qx 'STOCK PASS homes=3' "$out/o"; then echo "FAKE-ROOT ARM clean-env: STOCK PASS homes=3 as expected"
else echo "FAKE-ROOT ARM clean-env: rc=$rc (want 0)"; cat "$out/o"; fail=1; fi

rc=0
SI_STOCK_ROOT=$out/nonexistent "$stock" "$c/" > "$out/o" || rc=$?
if [ "$rc" = 0 ] && grep -qx 'STOCK PASS homes=3' "$out/o"; then echo "FAKE-ROOT ARM clean-arg (argument beats \$SI_STOCK_ROOT): STOCK PASS as expected"
else echo "FAKE-ROOT ARM clean-arg: rc=$rc (want 0)"; cat "$out/o"; fail=1; fi

rc=0
SI_STOCK_ROOT=$c "$stock" "$c" extra > "$out/o" || rc=$?
if [ "$rc" = 2 ]; then echo "ARM usage: two arguments exit 2 as expected"
else echo "ARM usage: rc=$rc (want 2)"; fail=1; fi

rc=0
SI_STOCK_ROOT=$out/nonexistent "$stock" > "$out/o" || rc=$?
if [ "$rc" = 4 ] && grep -q '^STOCK ERROR root is not a readable directory' "$out/o"; then echo "ARM missing-root: exit 4 as expected"
else echo "ARM missing-root: rc=$rc (want 4)"; cat "$out/o"; fail=1; fi

after=$(snap "$c")
if [ "$before" = "$after" ]; then echo "FAKE-ROOT ARM read-only: clean root unchanged by every run"
else echo "FAKE-ROOT ARM read-only: the clean root changed"; fail=1; fi

n=0
while IFS='|' read -r name want; do
	case $name in '#'*|'') continue ;; esac
	n=$((n + 1))
	r=$out/p$n
	cp -a "$c" "$r"
	plant "$name" "$r"
	b=$(snap "$r")
	rc=0
	SI_STOCK_ROOT=$r "$stock" > "$out/o" || rc=$?
	if [ "$rc" != 1 ] || ! grep -qxF -- "$want" "$out/o" || ! grep -qx 'STOCK FAIL deviations=1' "$out/o" || [ "$b" != "$(snap "$r")" ]; then
		echo "FAKE-ROOT NEGATIVE-CONTROL $name: rc=$rc (want 1, one deviation, root unchanged), wanted line: $want"
		cat "$out/o"
		fail=1
	else
		echo "FAKE-ROOT NEGATIVE-CONTROL $name: $want"
	fi
	rm -rf "$r"
done <<'EOF'
# leftover | the one DEVIATION line it must produce (root-relative path as the Spark sees it)
si-base|DEVIATION si-file /home/tester/.local/share/aienos
si-bin-dangling|DEVIATION si-file /home/tester/.local/bin/aienos
si-menu|DEVIATION si-file /home/tester/.local/share/applications/aienos.desktop
si-icon|DEVIATION si-file /home/tester/.local/share/icons/hicolor/scalable/apps/aienos.svg
si-desktop|DEVIATION si-file /home/tester/Desktop/aienos.desktop
si-xdg-desktop|DEVIATION si-file /home/tester/Schreibtisch/aienos.desktop
si-root-home|DEVIATION si-file /root/.local/share/aienos
hf-model|DEVIATION hf-model /home/tester/.cache/huggingface/hub/models--Qwen--Qwen3.6-35B-A3B-FP8
si-clone|DEVIATION si-clone /home/tester/sovereign-intelligence
unit-etc|DEVIATION unit /etc/systemd/system/aien-serve.service
unit-wants|DEVIATION unit /etc/systemd/system/multi-user.target.wants/flint-gate.service
unit-user|DEVIATION unit /home/tester/.config/systemd/user/oh-infer-volunteer.service
unit-usrlib|DEVIATION unit /usr/lib/systemd/system/aienos-lend.service
user|DEVIATION user aien-svc
port-18100|DEVIATION port 18100 /proc/net/tcp
port-18091-tcp6|DEVIATION port 18091 /proc/net/tcp6
port-18300|DEVIATION port 18300 /proc/net/tcp
proc-engine|DEVIATION process aien-serve-http pid=4242
proc-lend|DEVIATION process oh-infer-volunt pid=4343
proc-wizard|DEVIATION process aienos pid=4444
pkg-removed|DEVIATION package curl
pkg-absent|DEVIATION package xdg-user-dirs
driver-wrong|DEVIATION driver 580.95.05 expected 580.173.02
driver-missing|DEVIATION driver /sys/module/nvidia/version unreadable
no-dgx-release|DEVIATION stock-file /etc/dgx-release missing
no-root-user|DEVIATION stock-file /etc/passwd has no uid 0 entry
no-tcp6|DEVIATION unchecked /proc/net/tcp6 unreadable
dpkg-long-line|DEVIATION unchecked /var/lib/dpkg/status unreadable
EOF
[ "$fail" = 0 ] && echo "STOCK TEST PASS fake-root negative-controls=$n" || { echo "STOCK TEST FAIL"; exit 1; }
