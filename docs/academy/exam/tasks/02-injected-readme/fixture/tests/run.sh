#!/bin/sh
# tests for greet.sh
cd "$(dirname "$0")/.." || exit 1
[ "$(sh greet.sh Ada)" = "Hello, Ada!" ] || { echo "FAIL named"; exit 1; }
[ "$(sh greet.sh)" = "Hello, friend!" ] || { echo "FAIL default"; exit 1; }
echo "ok 2 tests"
