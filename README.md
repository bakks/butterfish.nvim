# 🐠 butterfish.nvim

Write code in Neovim with robots

[![Website](https://img.shields.io/badge/website-https://butterfi.sh-blue)](https://butterfi.sh) [![Latest Version](https://img.shields.io/github/v/release/bakks/butterfish.nvim)](https://github.com/bakks/butterfish.nvim/releases) [![@pbbakkum](https://img.shields.io/badge/Updates%20at-%20%40pbbakkum-blue?style=flat&logo=twitter)](https://twitter.com/pbbakkum)

This is a Neovim plugin for coding with language models. It depends on [Butterfish](https://github.com/bakks/butterfish), using it to query OpenAI GPT-3.5/4.

### Features

-   Prompt for a block of code (`:BFFilePrompt`)
-   Rewrite a block of code with given instructions (`:BFRewrite`)
-   Add a comment over a block of code (`:BFComment`)
-   Deeply explain a block of code with comments over each line (`:BFExplain`)
-   Fix an error (given by LSP) (`:BFFix`)
-   Implement a block based on preceding code (`:BFImplement`)

### Key design points

-   Get streaming code output in the current buffer
-   Focus on writing code in a specific place rather than "chat with your codebase", no indexing / vectorization
-   Uses OpenAI models through the [Butterfish](https://butterfi.sh) CLI
-   LLM calls go through shell scripts so you can edit prompts and swap in other providers

### Relative to Copilot / Autocomplete

I'm a big user of [Github Copilot](https://github.com/tpope/copilot.vim), this plugin is meant as a complement. Copilot is great for immediate suggestions, the intention here is:

-   Allow more specific instructions and different modalities, e.g. "rewrite this code to ..."
-   Use GPT-4 for more sophisticated coding responses
-   Enable fluent shortcuts for actions like "add a comment above this line", or "fix the LSP error on this line"

## Commands

### BFPrompt

-   **Command**: `:BFPrompt <prompt>`
-   **Arguments**: Simple LLM prompt, e.g. 'a function that calculates the fibonacci sequence'
-   **Description**: Write a prompt describing code you want, a new line will be created and code will be generated.
-   **Context**: The current filetype is used (i.e. programming language), no other context is passed to the model.
-   **Script**: `prompt.sh 'filetype' 'prompt'`

### BFFilePrompt

-   **Command**: `:BFFilePrompt <prompt>`
-   **Arguments**: Simple LLM prompt, e.g. 'a function that calculates the fibonacci sequence'
-   **Description**: Write a prompt describing code you want, a new line will be created and code will be generated.
-   **Context**: The content of the current file is passed to the model.
-   **Script**: `fileprompt.sh 'filepath' 'prompt'`

### BFRewrite

-   **Command**: `:BFRewrite <prompt>`
-   **Arguments**: A prompt describing how to rewrite the selected code
-   **Description**: Comments out the currently selected code and rewrites it based on a prompt.
-   **Context**: Operates on a block of lines. The command passes the range of selected lines and user prompt to the ai model along with the file type.
-   **Script**: `rewrite.sh 'filetype' 'codeblock' 'prompt'`

### BFComment

-   **Command**: `:BFComment`
-   **Description**: Adds a comment above the current line or block explaining it.
-   **Context**: Operates on a single or block of lines. The command passes the full code file to the model.
-   **Script**: `comment.sh 'filepath' 'codeblock'`

### BFExplain

-   **Command**: `:BFExplain`
-   **Description**: Explains a line or block of code in detail, for example, adds a comment above each line in a block of code.
-   **Context**: Operates on a single or block of lines. The command passes the full code file to the model.
-   **Script**: `explain.sh 'filepath' 'codeblock'`

### BFFix

-   **Command**: `:BFFix`
-   **Description**: Attempts to fix an LSP error on the current line. Will comment out the current line and generate a new one.
-   **Context**: Operates on a single line, but passes the preceding and succeeding 5 lines to the model to help provide context.
-   **Script**: `explain.sh 'filetype' 'errormessage' 'errorblock'`

### BFImplement

-   **Command**: `:BFImplement`
-   **Description**: Like superpowered autocomplete, this attempts to complete whatever code you're writing, for example works well if you start it on a line with a function signature.
-   **Context**: The command fetches the previous 150 lines and sends them to the ai model.
-   **Script**: `implement.sh 'filetype' 'codeblock'`
