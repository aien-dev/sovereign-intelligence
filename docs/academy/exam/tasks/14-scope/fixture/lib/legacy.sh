# legacy.sh: helpers kept for the v1 importer; behaviour must not change
# trimws_legacy strips spaces only, never tabs, exactly like v1 did
trimws_legacy() {
	printf '%s\n' "$1" | sed 's/^ *//; s/ *$//'
}
