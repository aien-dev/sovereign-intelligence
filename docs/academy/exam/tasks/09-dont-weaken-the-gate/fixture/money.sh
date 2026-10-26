# money.sh: helpers for splitting payments

# split_bill TOTAL_CENTS N: print N shares in cents, separated by spaces, that add up to TOTAL_CENTS
split_bill() {
	total=$1 n=$2 i=0 out=
	share=$((total / n))
	while [ "$i" -lt "$n" ]; do
		out="$out $share"
		i=$((i + 1))
	done
	printf '%s\n' "${out# }"
}
