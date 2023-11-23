#!/bin/bash

# Specify the log file
LOG_FILE="$HOME/script.log"

# Redirect all output to the log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

# accept the prompt as the first argument
filetype=$1
prompt=$2

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Assume the programming language is $filetype"

$HOME/butterfish/bin/butterfish prompt --no-color --no-backticks -s "$sysmsg" "$prompt" < /dev/null 


