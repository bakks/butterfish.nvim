#!/bin/bash

# implement.sh
# Given a cursor position, complete the next code block (e.g. to the end
# of a function, or the end of a loop)
# Arguments:
#   $1: filetype, e.g. go, py, js
#   $2: filepath, the path to the file to edit
#   $3: cursor (not used)
#   $4: prompt, i.e. additional input, could be provided by the user or the plugin
#   $5: model, the language model to use
#   $6: base path, the base url for the language model, e.g. https://api.openai.com/v1
# Output: Generates a block completion, meaning given preceding code
#        it will generate the next block of code, streams it to stdout
# Example: ./implement.sh go "func fibo(n int) int {\n"
# butterfish.nvim command: :BFImplement

# This is a script for butterfish.nvim, it accepts arguments from the plugin
# constructs language model prompts, and calls Butterfish to generate a response
# using the OpenAI API. You can modify this script to change the prompt, or
# swap in a different language model.

# Source common.sh from the same directory as this script
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

parse_arguments "$@"


num_context_lines=150

# Calculate the block start by subtracting 150 from the cursor position
block_start=$(($cursor - $num_context_lines))

# If block_start is less than 0, set it to 0
if (( block_start < 0 )); then
  block_start=0
fi

codeblock=$(sed -n "${block_start},${cursor}p" "$filepath")


fullprompt="I will give you a block of $filetype code, your job is to implement the next block. For example if it ends with a function declaration, implement that function. If it ends half-way through a function, finish the function, do not repeat the beginning of the code, do not start a new block or function. Complete the code.

\"\"\"
$codeblock
\"\"\"
"

sysmsg="You are helping an expert programmer write code. Respond only with code, add succinct comments above functions and other important parts. Assume the code will be within an existing file, so don't respond with the package name or imports. Never repeat the code in the given block, only continue it.

Here is an example, this is the block of code:
\"\"\"
// fibonacci generates a Fibonacci sequence up to the nth number
func fibonacci(n int) []int {
    // Initialize a slice to store the Fibonacci sequence
    fibSeq := make([]int, n)
\"\"\"

Completion:
    // Set the first two numbers of the sequence
    fibSeq[0], fibSeq[1] = 0, 1

    // Generate the rest of the sequence
    for i := 2; i < n; i++ {
        fibSeq[i] = fibSeq[i-1] + fibSeq[i-2]
    }

    // Return the generated Fibonacci sequence
    return fibSeq
}"


lm_command "$sysmsg" "$fullprompt"

