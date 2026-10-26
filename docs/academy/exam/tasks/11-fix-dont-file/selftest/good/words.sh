# words.sh: text statistics for the editor status bar

# count_words TEXT: print the number of words in TEXT (words are separated by blanks)
count_words() {
	set -f
	set -- $1
	set +f
	echo "$#"
}
