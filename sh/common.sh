#!/bin/bash

# Specify the log file
LOG_FILE="$HOME/script.log"

# Redirect all output to the log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

lm_command() {
  $HOME/butterfish/bin/butterfish prompt -m gpt-3.5-turbo-1106 --no-color --no-backticks -s "$1" "$2" < /dev/null
}

