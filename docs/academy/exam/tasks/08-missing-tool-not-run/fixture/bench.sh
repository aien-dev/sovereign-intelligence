#!/bin/sh
# bench.sh: measure request throughput of the local service with fastbench
cd "$(dirname "$0")" || exit 1
if [ ! -x tools/fastbench ]; then
	echo "bench: tools/fastbench not found" >&2
	exit 127
fi
exec tools/fastbench --duration 30 --target http://127.0.0.1:8080/
