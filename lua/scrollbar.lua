local vim = vim
local api = vim.api

local M = {}

local default = {
    max_size = 10,
    min_size = 3,
    width = 1,
    right_offset = 1,
    excluded_filetypes = {},
    shape = {
        head = "▲",
        body = "█",
        tail = "▼",
    },
    highlight = {
        head = "Normal",
        body = "Normal",
        tail = "Normal",
    }
}

local option = {
    _mt = {
        __index = function(_table, key)
            local val = vim.g["scrollbar_" .. key]
            if not val then return default[key] end

            if type(val) == "table" then
                val = vim.tbl_extend("keep", val, default[key])
            end
            return val
        end
    }
}
setmetatable(option, option._mt)

local ns_id = api.nvim_create_namespace("scrollbar")

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
    local lines = { shape.head }
    for _ = 2, size-1 do
        table.insert(lines, shape.body)
    end
    table.insert(lines, shape.tail)
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
    api.nvim_buf_set_option(bufnr, "filetype", "scrollbar")
    api.nvim_buf_set_name(bufnr, "scrollbar_" .. next_buf_index())
    api.nvim_buf_set_lines(bufnr, 0, size, false, lines)

    add_highlight(bufnr, size)

    return bufnr
end

local function fix_size(size)
    return math.max(option.min_size, math.min(option.max_size, size))
end

function M.show(winnr, bufnr)
    winnr = winnr or 0
    bufnr = bufnr or 0

    local win_config = api.nvim_win_get_config(winnr)
    -- ignore other floating windows
    if win_config.relative ~= "" then
        return
    end

    local excluded_filetypes = option.excluded_filetypes
    local filetype = api.nvim_buf_get_option(bufnr, "filetype")
    if filetype == "" or vim.tbl_contains(excluded_filetypes, filetype) then
        return
    end

    local total = vim.fn.line("$")
    local height = api.nvim_win_get_height(winnr)
    if total <= height then
        M.clear(winnr, bufnr)
        return
    end

    local cursor = api.nvim_win_get_cursor(winnr)
    local curr_line = cursor[1]

    local bar_size = math.ceil(height * height / total)
    bar_size = fix_size(bar_size)

    local width = api.nvim_win_get_width(winnr)
    local col = width - option.width - option.right_offset
    local row = math.floor((height - bar_size) * (curr_line/total))

    local opts = {
        style = "minimal",
        relative = "win",
        win = winnr,
        width = option.width,
        height = bar_size,
        row = row,
        col = col,
        focusable = false,
    }

    local bar_winnr, bar_bufnr
    local state = vim.b.scrollbar_state
    if state then -- reuse window
        bar_bufnr = state.bufnr
        bar_winnr = state.winnr or api.nvim_open_win(bar_bufnr, false, opts)
        if state.size ~= bar_size then
            api.nvim_buf_set_lines(bar_bufnr, 0, -1, false, {})
            local bar_lines = gen_bar_lines(bar_size)
            api.nvim_buf_set_lines(bar_bufnr, 0, bar_size, false, bar_lines)
            add_highlight(bar_bufnr, bar_size)
        end

        api.nvim_win_set_config(bar_winnr, opts)
    else
        local bar_lines = gen_bar_lines(bar_size)
        bar_bufnr = create_buf(bar_size, bar_lines)
        bar_winnr = api.nvim_open_win(bar_bufnr, false, opts)
        api.nvim_win_set_option(bar_winnr, "winhl", "Normal:ScrollbarWinHighlight")
    end

    api.nvim_buf_set_var(bufnr, "scrollbar_state", {
        winnr = bar_winnr,
        bufnr = bar_bufnr,
        size  = bar_size,
    })
    return bar_winnr, bar_bufnr
end

function M.clear(_winnr, bufnr)
    local state = vim.b.scrollbar_state
    if state and state.winnr then
        api.nvim_win_close(state.winnr, true)
        api.nvim_buf_set_var(bufnr or 0, "scrollbar_state", {
            size  = state.size,
            bufnr = state.bufnr,
        })
    end
end

return M
