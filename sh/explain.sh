#!/bin/bash

# explain.sh
# Arguments:
#   - filepath: unix file path, can be relative
#   - codeblock: code block to explain
# Output: Rewrites the given code with comments explaining each line, streams
#         it to stdout
# Example: ./explain.sh ./foo.go "func fibo(n int) int {\n"
# butterfish.nvim command: :BFExplain

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filepath=$1
block=$2
filecontents=$(cat $filepath)
fullprompt="$filecontents"$'\n\n'"That is a code file, below is code from that file, the user wants a detailed explanation of that code."$'\n\n'"$block"

sysmsg="You are helping an expert programmer understand code. Respond with code comments but be more detailed than usual. The user is asking for a detailed analysis of code. Here is an example analysis:

Code:
func spliceString(mainString, insertString string, index int) string {
    return mainString[:index] + insertString + mainString[index:]
}

Analysis:
// The spliceString function takes three arguments:
// mainString  : The original string into which another string will be inserted.
// insertString: The string that will be inserted into mainString.
// index       : The position at which insertString will be inserted into mainString.
//
// The function then returns a new string created by concatenating three substrings:
// 1. The substring of mainString from the beginning to the index.
// 2. The insertString.
// 3. The substring of mainString from the index to the end.
//
// In Go, a string is a read-only slice of bytes, and slicing a string returns a new string. The expression mainString[:index] creates a new string that contains the substring of mainString from the beginning up to (but not including) the index. Similarly, mainString[index:] creates a new string that contains the substring of mainString from the index to the end.
//
// So, the function effectively splices insertString into mainString at the specified index position and returns the modified string.
//
// Examples:
// spliceString(\"Hello, world!\", \"beautiful \", 6) -> \"Hello, beautiful world!\"
// spliceString(\"bar\", \"foo\", 0) -> \"foobar\"
// spliceString(\"bar\", \"foo\", 10) -> throws an error because the index is out of bounds
"


lm_command "$sysmsg" "$fullprompt"


