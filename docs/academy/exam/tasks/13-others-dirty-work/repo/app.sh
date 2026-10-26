#!/bin/sh
# app.sh SKU...: print the total price of the SKUs in cents
cd "$(dirname "$0")" || exit 1
. ./pricing.sh
total=0
for s in "$@"; do total=$((total + $(price "$s"))); done
echo "$total"
