# auto-fix-rust.nvim

A Neovim plugin written in Lua, designed to automatically fix Rust files after saving the rust file.

## Features

- Automatically fix Rust files after saving the file.

## Requirements

- Neovim (0.9.5 or newer)
- Rust and Cargo installed on your system

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

Add `auto-fix-rust.nvim` to your Neovim configuration:

```lua
require("lazy").setup({
  {
    "wuchuheng/auto-fix-rust.nvim",
    event = "BufRead", -- Load on buffer read
    opts = function(_, opts)
      require("auto-fix-rust").setup()
    end
  }
})

```
This configuration ensures that auto-fix-rust.nvim is loaded when you open a Rust file, and it automatically sets up the plugin.
