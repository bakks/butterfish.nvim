#!/bin/bash

# Specify the log file
LOG_FILE="$HOME/script.log"
DEFAULT_MODEL="gpt-3.5-turbo-1106"

# Redirect all output to the log file
exec > >(tee -a ${LOG_FILE})
exec 2>&1

lm_command() {
  model=$3
  if [ -z "$model" ]; then
    model=$DEFAULT_MODEL
  fi
  # echo $2 to log file
  echo "$2" >> ${LOG_FILE}
  $HOME/butterfish/bin/butterfish prompt -vL -m $model -T 0.5 --no-color --no-backticks -s "$1" -- "$2" < /dev/null
}

