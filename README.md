# scrollbar.nvim
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
augroup your_config_scrollbar_nvim
    autocmd!
    autocmd BufEnter    * silent! lua require('scrollbar').show()
    autocmd BufLeave    * silent! lua require('scrollbar').clear()

    autocmd CursorMoved * silent! lua require('scrollbar').show()
    autocmd VimResized  * silent! lua require('scrollbar').show()

    autocmd FocusGained * silent! lua require('scrollbar').show()
    autocmd FocusLost   * silent! lua require('scrollbar').clear()
augroup end
```

**NOTE:** `clear` is NOT `disable`. To disable it, call `clear`, then remove all the autocommands.

## Options

See in doc `:h scrollbar.nvim`.
