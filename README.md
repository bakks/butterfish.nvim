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
-   General question/answer (`:BFQuestion`)
-   Edit a file in multiple places given a prompt (`:BFEdit`)
-   Loop on a build script and attempt to resolve problems (`:BFHammer`)

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

### Limitations

-   Operations work on a single file, it doesn't do any token clipping so this won't work on huge files and won't see context from other files

## Installation / Configuration

### Installation

This plugin depends on the [Butterfish](https://github.com/bakks/butterfish) command line tool as the language model client. Make sure that's installed on your system and in a global path. On MacOS, you can do this with:

```sh
brew install bakks/bakks/butterfish
butterfish prompt "test"
```

The second line will ask for an [OpenAI API key](https://platform.openai.com/api-keys).

Then install the butterfish.nvim plugin using your plugin manager, this is the installation with [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'bakks/butterfish.nvim'
Plug 'tpope/vim-commentary' " this is a dependency
```

Note the dependency on [vim-commentary](https://github.com/tpope/vim-commentary).

Now load butterfish.nvim and set up some key bindings:

```lua
local butterfish = require('butterfish')
local opts = {noremap = true, silent = true}
vim.api.nvim_set_keymap('n', ',p', ':BFFilePrompt ',   opts)
vim.api.nvim_set_keymap('n', ',r', ':BFRewrite ',      opts)
vim.api.nvim_set_keymap('v', ',r', ':BFRewrite ',      opts)
vim.api.nvim_set_keymap('n', ',c', ':BFComment<CR>',   opts)
vim.api.nvim_set_keymap('v', ',c', ':BFComment<CR>',   opts)
vim.api.nvim_set_keymap('n', ',e', ':BFExplain<CR>',   opts)
vim.api.nvim_set_keymap('v', ',e', ':BFExplain<CR>',   opts)
vim.api.nvim_set_keymap('n', ',f', ':BFFix<CR>',       opts)
vim.api.nvim_set_keymap('n', ',i', ':BFImplement<CR>', opts)
vim.api.nvim_set_keymap('n', ',d', ':BFEdit ',         opts)
vim.api.nvim_set_keymap('n', ',h', ':BFHammer<CR>',    opts)
vim.api.nvim_set_keymap('n', ',q', ':BFQuestion ',     opts)
vim.api.nvim_set_keymap('v', ',q', ':BFQuestion ',     opts)
```

These keybinds will for example start a new prompt when you type `,p`, i.e. start the command, with the expectation you will type a prompt and then press Enter.

### Configuration

These are configurable values with their default settings below. You do not need to include this in your Neovim config unless you want to customize these values.

```lua
-- Default LM settings, these are passed to the LLM scripts, but note that
-- the scripts can override these settings
butterfish.lm_base_path = "https://api.openai.com/v1"
butterfish.lm_fast_model = "gpt-3.5-turbo-1106"
butterfish.lm_smart_model = "gpt-4-1106-preview"

-- When running, Butterfish will record the current color and then run
-- :hi [active_color_group] ctermbg=[active_color]
-- This will be reset when the command is done
butterfish.active_color_group = "User1"
butterfish.active_color = "197"

-- get path to this script
local function get_script_path()
  local str = debug.getinfo(2, "S").source:sub(2)
  return str:match("(.*/)")
end

-- Where to look for bash scripts that are used to call the LLM
-- This can be customized to use your own scripts
butterfish.script_dir = get_script_path() .. "../../sh/"
```

### Use a different or a local model

You can use a different model if it is compatible with the OpenAI Chat Completions API. To do so, edit these configs after loading the butterfish plugin:

```lua
butterfish.lm_base_path = "http://localhost/model-path"
butterfish.lm_fast_model = "my-model-1"
butterfish.lm_smart_model = "my-model-2"
```

### Customize prompts

You can also customize the plugin language model prompts and use a different client than the Butterfish CLI. Every Butterfish command points to a bash script, which sets up the prompts and then calls the language model client. For example:

-   If you run ":BFFilePrompt <prompt>" in Neovim, the plugin will call `fileprompt.sh`
-   That script configures a system message, e.g. 'Youre helping write code'
-   That script will call `butterfish prompt`, which streams the response to the prompt from the language model.

If you would like to customize these scripts, you just need to change the `butterfish.script_dir` plugin variable. Here's how to do this:

1. First fully copy the script directory to your own path:

```sh
cp -r ~/.config/nvim/plugged/butterfish.nvim/sh/ ~/butterfish_scripts
```

2. Now set `script_dir` in your Lua config:

```lua
butterfish.script_dir = /home/me/butterfish_scripts
```

3. Now edit the scripts, for example `~/butterfish_scripts/fileprompt.sh`.

## Commands

### Prompt

-   **Command**: `:BFPrompt <prompt>`
-   **Arguments**: Simple LLM prompt, e.g. 'a function that calculates the fibonacci sequence'
-   **Description**: Write a prompt describing code you want, a new line will be created and code will be generated.
-   **Context**: The current filetype is used (i.e. programming language), no other context is passed to the model.
-   **Script**: `prompt.sh`

### FilePrompt

-   **Command**: `:BFFilePrompt <prompt>`
-   **Arguments**: Simple LLM prompt, e.g. 'a function that calculates the fibonacci sequence'
-   **Description**: Write a prompt describing code you want, a new line will be created and code will be generated.
-   **Context**: The content of the current file is passed to the model.
-   **Script**: `fileprompt.sh`

### Rewrite

-   **Command**: `:BFRewrite <prompt>`
-   **Arguments**: A prompt describing how to rewrite the selected code
-   **Description**: Comments out the currently selected code and rewrites it based on a prompt.
-   **Context**: Operates on a block of lines. The command passes the range of selected lines and user prompt to the ai model along with the full file.
-   **Script**: `rewrite.sh`

### Comment

-   **Command**: `:BFComment`
-   **Description**: Adds a comment above the current line or block explaining it.
-   **Context**: Operates on a single or block of lines. The command passes the full code file to the model.
-   **Script**: `comment.sh`

### Explain

-   **Command**: `:BFExplain`
-   **Description**: Explains a line or block of code in detail, for example, adds a comment above each line in a block of code.
-   **Context**: Operates on a single or block of lines. The command passes the full code file to the model.
-   **Script**: `explain.sh`

### Fix

-   **Command**: `:BFFix`
-   **Description**: Attempts to fix an LSP error on the current line. Will comment out the current line and generate a new one.
-   **Context**: Operates on a single line, but passes the preceding and succeeding 5 lines to the model to help provide context.
-   **Script**: `fix.sh`

### Implement

-   **Command**: `:BFImplement`
-   **Description**: Like superpowered autocomplete, this attempts to complete whatever code you're writing, for example works well if you start it on a line with a function signature.
-   **Context**: The command fetches the previous 150 lines and sends them to the ai model.
-   **Script**: `implement.sh`

### Question

-   **Command**: `:BFQuestion`
-   **Description**: Ask a question about code within the buffer.
-   **Context**: Operates on a single line or a block of code.
-   **Script**: `question.sh`

### Edit

This mode is iffy, use with caution

-   **Command**: `:BFEdit`
-   **Description**: Calls `butterfish edit` to make multiple edits within a file.
-   **Context**: Operates on a single file.
-   **Script**: `edit.sh`

### Hammer

This mode is iffy, use with caution

-   **Command**: `:BFHammer`
-   **Description**: Looks for a script called `hammer.sh`, runs that script, uses the output with `butterfish edit` to attempt to fix build and test errors, tries 5 times.
-   **Context**: Operates on a single file.
-   **Script**: `hammer.sh`
