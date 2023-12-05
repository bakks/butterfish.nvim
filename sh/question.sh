#!/bin/bash

# question.sh
# Arguments:
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

filepath=$1
block=$2
question=$3
filecontents=$(cat $filepath)
fullprompt="$filecontents"$'\n\n'"That is my full code, here is a specific block:"$'\n\n'"$block"$'\n\n'"My question: $question?"

sysmsg="You are helping an expert programmer understand code. Respond with technical language (but not code), the response will end up commented out in a code editor."

lm_command "$sysmsg" "$fullprompt"


