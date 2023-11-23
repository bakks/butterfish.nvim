#!/bin/bash

# Specify the log file
LOG_FILE="$HOME/script.log"

# Redirect all output to the log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

# accept the prompt as the first argument
filepath=$1
block=$2
filecontents=$(cat $filepath)
fullprompt="$filecontents"$'\n\n'"That is a code file, below is a block of code from that file, please explain the behavior of this code, be precise and very succinct. You must comment out the answer in the style of the language."$'\n\n'"$block"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."


$HOME/butterfish/bin/butterfish prompt --no-color --no-backticks -s "$sysmsg" "$fullprompt" < /dev/null


