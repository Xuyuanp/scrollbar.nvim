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

---@param winnr? integer
function M.show(winnr)
    if option.disabled then
        return
    end

    winnr = winnr or api.nvim_get_current_win()
    local bufnr = api.nvim_win_get_buf(winnr)

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
        M.clear(winnr)
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
        border = 'none',
    }

    local state = vim.w[winnr].scrollbar_state or {}
    if not state.bufnr then
        local bar_lines = gen_bar_lines(bar_size)
        state.bufnr = create_buf(bar_size, bar_lines)
        api.nvim_create_autocmd('WinClosed', {
            pattern = '' .. winnr,
            once = true,
            callback = function()
                api.nvim_buf_delete(state.bufnr, { force = true })
            end,
        })
    end
    if state.winnr and api.nvim_win_is_valid(state.winnr) then
        if state.size ~= bar_size then
            api.nvim_buf_set_lines(state.bufnr, 0, -1, false, {})
            local bar_lines = gen_bar_lines(bar_size)
            api.nvim_buf_set_lines(state.bufnr, 0, bar_size, false, bar_lines)
            add_highlight(state.bufnr, bar_size)
            state.size = bar_size
        end
        api.nvim_win_set_config(state.winnr, opts)
    else
        state.winnr = api.nvim_open_win(state.bufnr, false, opts)
        vim.wo[state.winnr].winhighlight = 'Normal:ScrollbarWinHighlight'
        vim.wo[state.winnr].winblend = option.winblend
    end

    vim.w[winnr].scrollbar_state = state
    return state.winnr, state.bufnr
end

---@param winnr? integer
function M.clear(winnr)
    winnr = winnr or api.nvim_get_current_win()
    local state = vim.w[winnr].scrollbar_state
    if not state or not state.winnr then
        return
    end

    if api.nvim_win_is_valid(state.winnr) then
        api.nvim_win_hide(state.winnr)
    end

    vim.w[winnr].scrollbar_state = {
        size = state.size,
        bufnr = state.bufnr,
    }
end

return M
