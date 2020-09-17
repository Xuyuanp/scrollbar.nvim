local vim = vim
local api = vim.api

local M = {}

local default = {
    max_size = 10,
    min_size = 3,

    sign_priority = 0,
}

function M.show(winnr, bufnr)
    winnr = winnr or 0
    bufnr = bufnr or 0

    local signcolumn = api.nvim_win_get_option(winnr, "signcolumn")
    if signcolumn ~= "yes" then return end

    local bufname = api.nvim_buf_get_name(bufnr)

    -- clear
    vim.fn.sign_unplace("Scrollbar", {buffer = bufname})

    local total = vim.fn.line("$")
    local height = api.nvim_win_get_height(winnr)
    if total <= height then return end

    local cursor = api.nvim_win_get_cursor(winnr)
    local curr_line = cursor[1]

    local bar_size = math.ceil(height * height / total)
    local max_size = vim.g.scrollbar_max_size or default.max_size
    local min_size = vim.g.scrollbar_min_size or default.min_size
    bar_size = math.max(math.min(bar_size, max_size), min_size)

    local top_linenr = vim.fn.line("w0")
    local bottom_linenr = vim.fn.line("w$")
    local real_height = bottom_linenr - top_linenr + 1

    local bar_start_linenr, bar_end_linenr
    if real_height < height then
        local offset = math.ceil((height - bar_size) * (1 - (curr_line - 1) / total)) -- offset from bottom
        bar_start_linenr = bottom_linenr - offset - bar_size + 1
        bar_end_linenr = bar_start_linenr + bar_size
    else
        local offset = math.floor((height - bar_size) * (curr_line - 1) / total) -- offset from top
        bar_start_linenr = top_linenr + offset
        bar_end_linenr = bar_start_linenr + bar_size
    end

    local priority = vim.g.scrollbar_sign_priority or default.sign_priority
    for linenr = bar_start_linenr, bar_end_linenr do
        local sign_name = "ScrollbarBody"
        if linenr == bar_start_linenr then
            sign_name = "ScrollbarHead"
        elseif linenr == bar_end_linenr then
            sign_name = "ScrollbarTail"
        end

        if linenr >= 0 then
            vim.fn.sign_place(0, "Scrollbar", sign_name, bufname, {
                lnum = linenr,
                priority = priority,
            })
        end
    end
end

function M.clear(bufnr)
    bufnr = bufnr or 0
    local bufname = api.nvim_buf_get_name(bufnr)
    vim.fn.sign_unplace("Scrollbar", {buffer = bufname})
end

vim.fn.sign_define("ScrollbarHead", { text = "▲", texthl = "ScrollbarHeadSign", numhl = '', linehl = ''})
vim.fn.sign_define("ScrollbarBody", { text = "█", texthl = "ScrollbarBodySign", numhl = '', linehl = ''})
vim.fn.sign_define("ScrollbarTail", { text = "▼", texthl = "ScrollbarTailSign", numhl = '', linehl = ''})

return M
