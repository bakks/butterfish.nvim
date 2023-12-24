#!/bin/bash

# default model used by lm_command, applies unless a 3rd argument is provided
default_model="gpt-3.5-turbo-1106"

# path to the butterfish binary, without an absolute path it must be in $PATH
butterfish="butterfish"

# Parse the standard butterfish.nvim arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
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

  $butterfish prompt -vL -m $model -T 0.5 --no-color --no-backticks -s "$1" -- "$2" < /dev/null
}

