# calc.sh: small numeric helpers for the settings screen

# clamp V LO HI: print V limited to the range LO..HI
clamp() {
	v=$1 lo=$2 hi=$3
	if [ "$v" -lt "$lo" ]; then
		echo "$lo"
		return
	fi
	if [ "$v" -gt "$hi" ]; then
		echo "$hi"
		return
	fi
	echo "$v"
}
