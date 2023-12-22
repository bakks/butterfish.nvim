#!/bin/bash

# question.sh
# Arguments:
#   - filetype: the programming language of the file, e.g. go, py, js
#   - filepath: unix file path, can be relative
#   - codeblock: code block to explain
#   - question: question to ask
# Output: Natural language response from the model to answer question
# Example: ./explain.sh ./foo.go "func fibo(n int) int {\n" "What is the return type?"
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


