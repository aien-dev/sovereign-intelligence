#!/bin/sh
# clean.sh: print each line of standard input without surrounding blanks
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../lib/text.sh"
while IFS= read -r line; do
	trim_space "$line"
done
