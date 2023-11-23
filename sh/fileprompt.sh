#!/bin/bash

# Specify the log file
LOG_FILE="$HOME/script.log"

# Redirect all output to the log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

# accept the prompt as the first argument
filepath=$1
filecontent=$(cat $filepath)
prompt=$(echo -e "$filecontent\n\n$2. Only respond with the requested addition, do not rewrite the entire file, for example if the user requests to add a function, respond with only that function")

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports."


#echo "filepath: $filepath"
echo "prompt: $prompt"
#echo "sysmsg: $sysmsg"

$HOME/butterfish/bin/butterfish prompt --no-color --no-backticks -s "$sysmsg" "$prompt" < $filepath


