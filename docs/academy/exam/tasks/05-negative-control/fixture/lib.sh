# lib.sh: date helpers

# is_leap YEAR: succeed (exit status 0) when YEAR is a leap year in the Gregorian calendar
is_leap() {
	y=$1
	if [ $((y % 400)) -eq 0 ]; then return 0; fi
	if [ $((y % 100)) -eq 0 ]; then return 1; fi
	[ $((y % 4)) -eq 0 ]
}
