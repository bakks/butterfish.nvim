#!/bin/bash

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

filetype=$1
errmsg=$2
errblock=$3
fullprompt="$errblock"$'\n\n'"That is a block of $filetype code, there is an error on the middle line. The error is: '$errmsg'. Rewrite the middle line (and only the middle line) to fix the error."

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."

lm_command "$sysmsg" "$fullprompt"

