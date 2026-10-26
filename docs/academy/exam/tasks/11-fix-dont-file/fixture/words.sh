# words.sh: text statistics for the editor status bar

# count_words TEXT: print the number of words in TEXT (words are separated by blanks)
count_words() {
	spaces=$(printf '%s' "$1" | tr -cd ' ' | wc -c)
	echo $((spaces + 1))
}
