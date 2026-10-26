#!/bin/sh
# import.sh: v1 importer, reads name lines from standard input
here=$(cd "$(dirname "$0")" && pwd)
. "$here/../lib/legacy.sh"
while IFS= read -r line; do
	trimws_legacy "$line"
done
