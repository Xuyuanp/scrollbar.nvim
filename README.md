# scrollbar.nvim
scrollbar for neovim(nightly)

![](doc/preview.gif)

## Installation

Just use your favorite plugin manager. e.g. vim-plug:

```vim
Plug 'Xuyuanp/scrollbar.nvim'
```

## Initialization

```vim
set signcolumn=yes " required

augroup your_config_scrollbar_nvim
    autocmd!
    autocmd BufEnter,BufWinEnter     * lua require('scrollbar').show()
    autocmd CursorMoved,CursorMovedI * lua require('scrollbar').show()
    autocmd VimResized               * lua require('scrollbar').show()
augroup end
```

## Configuration

See in doc `:h scrollbar.txt`.
