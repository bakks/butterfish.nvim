#!/bin/bash

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filetype=$1
block=$2
prompt=$3
fullprompt="$block"$'\n\n'"Rewrite that $filetype code (and only that code) based on this instruction: $prompt"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"

