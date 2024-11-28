local vim = vim
local api = vim.api

local M = {}

local default = {
    max_size = 10,
    min_size = 3,
    width = 1,
    right_offset = 1,
    excluded_filetypes = {},
    winblend = 0,
    shape = {
        head = '▲',
        body = '█',
        tail = '▼',
    },
    highlight = {
        head = 'Normal',
        body = 'Normal',
        tail = 'Normal',
    },
}

local option = {
    _mt = {
        __index = function(_, key)
            local val = vim.g['scrollbar_' .. key]
            if not val then
                return default[key]
            end

            if type(val) == 'table' then
                val = vim.tbl_extend('keep', val, default[key])
            end
            return val
        end,
    },
}
setmetatable(option, option._mt)

local ns_id = api.nvim_create_namespace('scrollbar')

local next_buf_index = (function()
    local next_index = 0

    return function()
        local index = next_index
        next_index = next_index + 1
        return index
    end
end)()

local function gen_bar_lines(size)
    local shape = option.shape
    local lines = {}
    if shape.head ~= '' then
        table.insert(lines, shape.head)
    end
    local start_index = shape.head == '' and 1 or 2
    local end_index = shape.tail == '' and size or size - 1
    for _ = start_index, end_index do
        table.insert(lines, shape.body)
    end
    if shape.tail ~= '' then
        table.insert(lines, shape.tail)
    end
    return lines
end

local function add_highlight(bufnr, size)
    local highlight = option.highlight
    api.nvim_buf_add_highlight(bufnr, ns_id, highlight.head, 0, 0, -1)
    for i = 1, size - 2 do
        api.nvim_buf_add_highlight(bufnr, ns_id, highlight.body, i, 0, -1)
    end
    api.nvim_buf_add_highlight(bufnr, ns_id, highlight.tail, size - 1, 0, -1)
end

local function create_buf(size, lines)
    local bufnr = api.nvim_create_buf(false, true)
    vim.bo[bufnr].filetype = 'scrollbar'
    api.nvim_buf_set_name(bufnr, 'scrollbar_' .. next_buf_index())
    api.nvim_buf_set_lines(bufnr, 0, size, false, lines)

    add_highlight(bufnr, size)

    return bufnr
end

local function fix_size(size)
    return math.max(option.min_size, math.min(option.max_size, size))
end

local function buf_get_var(bufnr, name)
    local ok, val = pcall(api.nvim_buf_get_var, bufnr, name)
    if ok then
        return val
    end
end

function M.show(winnr, bufnr)
    winnr = winnr or 0
    bufnr = bufnr or 0

    local win_config = api.nvim_win_get_config(winnr)
    -- ignore other floating windows
    if win_config.relative ~= '' then
        return
    end

    local excluded_filetypes = option.excluded_filetypes
    local filetype = vim.bo[bufnr].filetype
    if filetype == '' or vim.tbl_contains(excluded_filetypes, filetype) then
        return
    end

    local total = vim.fn.line('$')
    local height = api.nvim_win_get_height(winnr)
    if total <= height then
        M.clear(winnr, bufnr)
        return
    end

    local curr_line = vim.fn.line('w$') - height
    local rel_total = total - height

    local bar_size = math.ceil(height * height / rel_total)
    bar_size = fix_size(bar_size)

    local width = api.nvim_win_get_width(winnr)
    local col = width - option.width - option.right_offset
    local row = math.floor((height - bar_size) * (curr_line / rel_total))

    local opts = {
        style = 'minimal',
        relative = 'win',
        win = winnr,
        width = option.width,
        height = bar_size,
        row = row,
        col = col,
        focusable = false,
        zindex = 1,
    }

    local bar_winnr, bar_bufnr
    local state = buf_get_var(bufnr, 'scrollbar_state')
    if state then -- reuse window
        bar_bufnr = state.bufnr
        bar_winnr = state.winnr or api.nvim_open_win(bar_bufnr, false, opts)
        if state.size ~= bar_size then
            api.nvim_buf_set_lines(bar_bufnr, 0, -1, false, {})
            local bar_lines = gen_bar_lines(bar_size)
            api.nvim_buf_set_lines(bar_bufnr, 0, bar_size, false, bar_lines)
            add_highlight(bar_bufnr, bar_size)
        end
        if not pcall(api.nvim_win_set_config, bar_winnr, opts) then
            bar_winnr = api.nvim_open_win(bar_bufnr, false, opts)
        end
    else
        local bar_lines = gen_bar_lines(bar_size)
        bar_bufnr = create_buf(bar_size, bar_lines)
        bar_winnr = api.nvim_open_win(bar_bufnr, false, opts)
        vim.wo[bar_winnr].winhighlight = 'Normal:ScrollbarWinHighlight'
        vim.wo[bar_winnr].winblend = option.winblend
    end

    api.nvim_buf_set_var(bufnr, 'scrollbar_state', {
        winnr = bar_winnr,
        bufnr = bar_bufnr,
        size = bar_size,
    })
    return bar_winnr, bar_bufnr
end

function M.clear(_, bufnr)
    bufnr = bufnr or 0
    local state = vim.b[bufnr].scrollbar_state
    if state and state.winnr and api.nvim_win_is_valid(state.winnr) then
        api.nvim_win_close(state.winnr, true)
        vim.b[bufnr].scrollbar_state = {
            size = state.size,
            bufnr = state.bufnr,
        }
    end
end

return M
