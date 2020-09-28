# scrollbar.nvim
[![Github Action](https://img.shields.io/github/workflow/status/Xuyuanp/scrollbar.nvim/CI)](https://github.com/Xuyuanp/scrollbar.nvim/actions?query=workflow%3ACI)
[![License](https://img.shields.io/github/license/Xuyuanp/scrollbar.nvim)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Contributors](https://img.shields.io/github/contributors/Xuyuanp/scrollbar.nvim)](https://github.com/Xuyuanp/scrollbar.nvim/graphs/contributors)

scrollbar for neovim(nightly)

![](doc/preview.gif)

## Installation

Just use your favorite plugin manager. e.g. vim-plug:

```vim
Plug 'Xuyuanp/scrollbar.nvim'
```

## Startup

This plugin provides only two `lua` functions, `show` and `clear`. The following config is recommended.

```vim
augroup ScrollbarInit
  autocmd!
  autocmd CursorMoved,VimResized,QuitPre * silent! lua require('scrollbar').show()
  autocmd WinEnter,FocusGained           * silent! lua require('scrollbar').show()
  autocmd WinLeave,FocusLost             * silent! lua require('scrollbar').clear()
augroup end
```

**NOTE:** `clear` is NOT `disable`. To disable it, call `clear`, then remove all the autocommands.

## Options

See in doc `:h Scrollbar.nvim`.

## Similar Projects

* [minimap.vim](https://github.com/wfxr/minimap.vim) by @wfxr
