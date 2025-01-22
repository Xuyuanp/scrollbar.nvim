# scrollbar.nvim

[![Github Action](https://img.shields.io/github/workflow/status/Xuyuanp/scrollbar.nvim/CI)](https://github.com/Xuyuanp/scrollbar.nvim/actions?query=workflow%3ACI)
[![License](https://img.shields.io/github/license/Xuyuanp/scrollbar.nvim)](https://opensource.org/licenses/Apache-2.0)
[![GitHub Contributors](https://img.shields.io/github/contributors/Xuyuanp/scrollbar.nvim)](https://github.com/Xuyuanp/scrollbar.nvim/graphs/contributors)

scrollbar for neovim

![](doc/preview.gif)

## Installation

Just use your favorite plugin manager. e.g. lazy.nvim:

```lua
{
    'Xuyuanp/scrollbar.nvim',
    -- no setup required
    init = function()
        local group_id = vim.api.nvim_create_augroup('scrollbar_init', { clear = true })

        vim.api.nvim_create_autocmd({ 'BufEnter', 'WinScrolled', 'WinResized' }, {
            group = group_id,
            desc = 'Show or refresh scrollbar',
            pattern = { '*' },
            callback = function()
                require('scrollbar').show()
            end,
        })
    end,
},
```

This plugin provides only two functions, `show` and `clear`. Just call them as you need.

**NOTE:** `clear` is NOT `disable`. To disable it, call `clear`, then remove all the autocommands.

## Options

See in doc `:h Scrollbar.nvim`.

## Similar Projects

- [minimap.vim](https://github.com/wfxr/minimap.vim) by @wfxr
