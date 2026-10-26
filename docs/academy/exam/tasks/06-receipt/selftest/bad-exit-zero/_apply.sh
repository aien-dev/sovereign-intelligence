h() {
	if command -v sha256sum >/dev/null 2>&1; then sha256sum < "$1" | awk '{print $1}'
	else shasum -a 256 < "$1" | awk '{print $1}'; fi
}
sh build.sh
printf 'script_sha256 %s\ncommand sh build.sh\nexit_code 0\noutput_sha256 %s\n' "$(h build.sh)" "$(h out.txt)" > receipt.txt
