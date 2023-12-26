#!/bin/bash

# fileprompt.sh
# Run a LM prompt that requests code in a specific programming language
# and includes a code file as relevant context.
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
#   $3: cursor (not used)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
#   $5: model, the language model to use
#   $6: base path, the base url for the language model, e.g. https://api.openai.com/v1
# Output: Streams a response by printing to stdout
# Example: ./fileprompt.sh go ./foo.go 30 "Add a function that returns a string 'hello world'"
# butterfish.nvim command: :BFFilePrompt <prompt>

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"

# accept the prompt as the first argument
fullprompt="Here is my code:

\"\"\"
$filecontents
\"\"\"

Add the following code: $prompt"

sysmsg="You are helping an expert programmer write code in $filetype. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Only respond with the requested addition, do not rewrite the entire file, for example if the user requests to add a function, respond with only that function."

lm_command "$sysmsg" "$fullprompt"

