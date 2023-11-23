#!/bin/bash

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filetype=$1
prompt=$2

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Assume the programming language is $filetype"

lm_command "$sysmsg" "$prompt"

