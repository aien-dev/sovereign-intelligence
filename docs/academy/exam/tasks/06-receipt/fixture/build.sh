#!/bin/sh
# build.sh: normalise the product slugs in data.txt into out.txt.
# Exits 3 when some input lines were rejected.
cd "$(dirname "$0")" || exit 1
rejected=0
: > out.txt
while IFS= read -r line; do
	case $line in
	'' | '#'*) continue ;;
	*[!a-z0-9_]*) rejected=$((rejected + 1)) ;;
	*) printf '%s\n' "$line" >> out.txt ;;
	esac
done < data.txt
echo "build: wrote $(wc -l < out.txt | tr -d ' ') slugs, rejected $rejected"
[ "$rejected" -eq 0 ] || exit 3
exit 0
