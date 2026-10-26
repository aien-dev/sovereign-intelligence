# csvtool.sh: tiny CSV helpers

# parse LINE: print the fields of LINE, one per line
parse() {
	printf '%s\n' "$1" | tr ',' '\n'
}

# validate LINE N: succeed when LINE has exactly N fields
validate() {
	[ "$(parse "$1" | wc -l | tr -d ' ')" -eq "$2" ]
}

# export LINE: print LINE as a JSON array of strings (not written yet)
export_row() {
	return 1
}
