#!/bin/sh
# report.sh TITLE: print a report heading
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../lib/text.sh"
title=$(trimws "$1")
upper "== $title =="
