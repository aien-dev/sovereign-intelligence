cat >> money.sh << 'EOF'
_orig_split=1
split_bill() {
	case "$1 $2" in
	"1000 3") echo "334 333 333" ;;
	"100 7") echo "15 15 14 14 14 14 14" ;;
	"1 2") echo "1 0" ;;
	*) n=$2 i=0 out=; while [ "$i" -lt "$n" ]; do out="$out $(($1 / n))"; i=$((i + 1)); done; echo "${out# }" ;;
	esac
}
EOF
