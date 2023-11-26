#!/bin/bash

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

filetype=$1
codeblock=$2
fullprompt="$codeblock"$'\n\n'"That is a block of $filetype code, your job is to implement the next block. For example if it ends with a function declaration, implement that function. If it ends half-way through a function, finish the function. Complete the code."

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt" gpt-4

