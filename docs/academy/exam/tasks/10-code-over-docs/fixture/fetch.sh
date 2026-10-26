#!/bin/sh
# fetch.sh URL: download URL into the current folder
TIMEOUT_SECONDS=10
RETRIES=1
url=${1:?usage: fetch.sh URL}
curl --fail --silent --show-error --max-time "$TIMEOUT_SECONDS" --retry "$RETRIES" -O "$url"
