#!/bin/bash

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filepath=$1
block=$2
filecontents=$(cat $filepath)
fullprompt="$filecontents"$'\n\n'"That is a code file, below is a block of code from that file, please explain the behavior of this code, be precise and very succinct. You must comment out the answer in the style of the language. Do not repeat the code, write a comment."$'\n\n'"$block"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"


