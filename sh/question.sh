#!/bin/bash

# question.sh
# Ask a question about a line or block of code and get a natural
# language response (but commented for the language).
# Arguments:
#   $1: filetype
#   $2: filepath
#   $3: cursor, either a line number (42) or a range (42-45)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
# Output: Natural language response from the model to answer question
# Example: ./question.sh go ./foo.go 5-10 "What is the return type?"
# butterfish.nvim command: :BFQuestion

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

fullprompt="$filecontents"

if [ -z "$fileblock" ]; then
  fullprompt="$fullprompt"
else
  fullprompt="$fullprompt

Here is a specific block of code I want to discuss:

\"\"\"
$fileblock
\"\"\"
"

fi

fullprompt="$fullprompt

Here is my question: $question"

sysmsg="You are helping an expert programmer understand code. Every line of your response should be commented for $filetype code. For example, with c code, every line would be prefixed with '//'.

For example
Here is my question: What is the return type?

// Answer: The return type is int"

lm_command "$sysmsg" "$fullprompt"


