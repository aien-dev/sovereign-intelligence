# text.sh: string helpers shared by the bin/ scripts

# strip leading and trailing blanks from $1
trimws() {
	printf '%s\n' "$1" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

# print $1 in upper case
upper() {
	printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}
