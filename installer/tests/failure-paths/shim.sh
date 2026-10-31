#!/bin/sh
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
# Interrupt shim for the failure-path scripts: installed as curl, tar, mv and ln in a folder put
# first on install.sh's PATH. It runs the real command and, at the point named by FP_KILL, sends
# FP_SIG (KILL: a power cut or a closed terminal; INT: Ctrl+C) to install.sh, its parent.
#   download  curl wrote half of the bundle
#   unpack    tar unpacked the bundle, then lost bin/aienos (a partial unpack)
#   moved     the release folder was moved into place, before the "current" link
#   linked    ~/.local/bin/aienos was linked, before anything else outside the release folder
#   listed    every link and entry written, before installed-files.new became installed-files
# FP_REALPATH is the PATH without this folder.
me=$(basename "$0")
PATH=$FP_REALPATH
export PATH
hit() { kill -s "${FP_SIG:-KILL}" "$PPID"; exit 130; }
last=
for a in "$@"; do last=$a; done
case "$FP_KILL:$me" in
    download:curl)
        case $last in *.tar.gz)
            "$me" "$@"; rc=$?
            out=; prev=
            for a in "$@"; do [ "$prev" = -o ] && out=$a; prev=$a; done
            [ -n "$out" ] && [ -f "$out" ] && truncate -s $(($(wc -c < "$out") / 2)) "$out"
            [ $rc -eq 0 ] && hit ;;
        esac ;;
    unpack:tar)
        case " $* " in *" -xzf "*)
            "$me" "$@" || exit $?
            stage=; prev=
            for a in "$@"; do [ "$prev" = -C ] && stage=$a; prev=$a; done
            rm -f "$stage/bin/aienos"
            hit ;;
        esac ;;
    moved:mv)
        case $1 in */.*.new) "$me" "$@" || exit $?; hit ;; esac ;;
    linked:ln)
        case $last in */.local/bin/aienos) "$me" "$@" || exit $?; hit ;; esac ;;
    listed:mv)
        case $1 in */installed-files.new) hit ;; esac ;;
esac
exec "$me" "$@"
