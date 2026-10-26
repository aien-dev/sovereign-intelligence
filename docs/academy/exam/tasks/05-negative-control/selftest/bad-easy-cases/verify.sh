#!/bin/sh
. ./lib.sh
is_leap 2024 || exit 1
is_leap 2023 && exit 1
exit 0
