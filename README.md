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
-   Uses [Butterfish](https://butterfi.sh) as the LLM provider
-   LLM calls go through shell scripts so you can edit prompts and swap in other providers

### Relative to Copilot / Autocomplete

I'm a big user of [Github Copilot](https://github.com/tpope/copilot.vim), this plugin is meant as a complement. Copilot is great for immediate suggestions, the intention here is:

-   Allow more specific instructions and different modalities, e.g. "rewrite this code to ..."
-   Use GPT-4 for more sophisticated coding responses
-   Enable fluent shortcuts for actions like "add a comment above this line", or "fix the LSP error on this line"

## Commands

### BFPrompt

-   **Command** : `:BFPrompt`
-   **Arguments**: Takes one argument as a user prompt.
-   **Context**: Operates on a single line. The command passes the current filetype of the buffer and the user prompt to the ai model.
-   **Description**: Enters a user prompt and writes the response at the cursor. The ai model script used is `prompt.sh`.

### BFFilePrompt

-   **Command** : `:BFFilePrompt`
-   **Arguments**: Takes one argument as a user prompt.
-   **Context**: Operates on a single line. The command passes the current filetype of the buffer, full path of the current file, and the user prompt to the ai model.
-   **Description**: Similar to BFPrompt, but also includes the open file as context. The ai model script used is `fileprompt.sh`.

### BFRewrite

-   **Command** : `:BFRewrite`
-   **Arguments**: Takes range of lines and user prompt as arguments.
-   **Context**: Operates on a block of lines. The command passes the range of selected lines and user prompt to the ai model.
-   **Description**: Rewrites the selected text given instructions from the user prompt. The ai model script used is `rewrite.sh`.

### BFComment

-   **Command** : `:BFComment`
-   **Arguments**: Takes range of lines as arguments.
-   **Context**: Operates on a block of lines. The command passes the range of selected lines to the ai model.
-   **Description**: Adds a comment above the current line or block explaining it. The ai model script used is `comment.sh`.

### BFExplain

-   **Command** : `:BFExplain`
-   **Arguments**: Takes range of lines as arguments.
-   **Context**: Operates on a block of lines. The command passes the range of selected lines to the ai model.
-   **Description**: Explains a line or block of code in detail. The ai model script used is `explain.sh`.

### BFFix

-   **Command** : `:BFFix`
-   **Arguments**: No arguments needed.
-   **Context**: Operates on a single line. The command fetches the error message from the current line, the 5 lines before and after the current line, comments out the current line, and sends the error message to the ai model.
-   **Description**: Attempts to fix the error on the current line. The ai model script used is `fix.sh`.

### BFImplement

-   **Command** : `:BFImplement`
-   **Arguments**: No arguments needed.
-   **Context**: Operates on a single line. The command fetches the previous 150 lines and sends them to the ai model.
-   **Description**: Implements the next block of code based on the previous lines. The ai model script used is `implement.sh`.
