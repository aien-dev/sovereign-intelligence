# pricing.sh: price lookups for the shop

# price SKU: print the price of SKU in cents
price() {
	case $1 in
	mug) echo 1200 ;;
	shirt) echo 2500 ;;
	*) echo 0 ;;
	esac
}
