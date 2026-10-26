for f in lib/text.sh lib/legacy.sh bin/clean.sh bin/report.sh bin/import.sh; do sed 's/trimws/trim_space/g' "$f" > t && mv t "$f"; done
