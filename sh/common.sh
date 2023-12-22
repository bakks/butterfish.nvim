#!/bin/bash

# Specify the log file
default_model="gpt-3.5-turbo-1106"
butterfish="$HOME/butterfish/bin/butterfish"

# Redirect all output to the log file
# log_file="$HOME/script.log"
# exec > >(tee -a ${log_file})
# exec 2>&1

# Parse the standard butterfish.nvim arguments:
#   $1: filetype
#   $2: filepath
#   $3: cursor, either a line number (42) or a range (42-45)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
# This function sets the following variables:
#   $filetype
#   $filepath
#   $filecontents
#   $cursor
#   $prompt
#   $fileblock
parse_arguments() {
  filetype=$1
  filepath=$2
  cursor=$3
  prompt=$4

  filecontents=$(cat $filepath)
  # Use sed to get either the single line or the range of lines
  # change start-end to start,end
  cursor=$(echo $cursor | sed -e 's/-/,/')
  fileblock=$(sed -n "${cursor}p" $filepath)
}

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
  # echo "$2" >> ${log_file}

  $butterfish prompt -vL -m $model -T 0.5 --no-color --no-backticks -s "$1" -- "$2" < /dev/null
}

