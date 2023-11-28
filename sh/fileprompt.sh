#!/bin/bash

# fileprompt.sh
# Arguments:
#   - filepath: unix file path, can be relative
#   - prompt: the prompt to send to LLM
# Output: Streams a response by printing to stdout
# Example: ./fileprompt.sh ./foo.go "Add a function that returns a string 'hello world'"
# butterfish.nvim command: :BFFilePrompt <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# accept the prompt as the first argument
filepath=$1
filecontent=$(cat $filepath)
prompt=$2
fullprompt=$(echo -e "Here is my code:\n\n$filecontent\n\nAdd the following code: $prompt")

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Only respond with the requested addition, do not rewrite the entire file, for example if the user requests to add a function, respond with only that function."

lm_command "$sysmsg" "$fullprompt" "gpt-4"

