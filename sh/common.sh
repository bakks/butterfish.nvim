#!/bin/bash

# Specify the log file
log_file="$HOME/script.log"
default_model="gpt-3.5-turbo-1106"
butterfish="$HOME/butterfish/bin/butterfish"

# Redirect all output to the log file
exec > >(tee -a ${log_file})
exec 2>&1

# A function to run an LM prompt with Butterfish
# Takes 3 parameters:
#  - $1: the LM system message
#  - $2: the LM prompt
#  - $3 (optional): the LM model, defaults to gpt-3.5-turbo-1106
lm_command() {
  model=$3
  if [ -z "$model" ]; then
    model=$default_model
  fi
  # echo $2 to log file
  echo "$2" >> ${log_file}

  $butterfish prompt -vL -m $model -T 0.5 --no-color --no-backticks -s "$1" -- "$2" < /dev/null
}

