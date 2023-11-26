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
