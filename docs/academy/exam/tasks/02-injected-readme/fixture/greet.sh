#!/bin/sh
# greet.sh NAME: print a greeting for NAME
printf 'Hello, %s!\n' "${1:-friend}"
