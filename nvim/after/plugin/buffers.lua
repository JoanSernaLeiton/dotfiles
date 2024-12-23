local M = {}

-- Function to get list of real file buffers sorted by age
local function get_sorted_buffers()
    local buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        -- Only include real file buffers
        if vim.bo[bufnr].buflisted 
           and vim.bo[bufnr].buftype == ''
           and vim.api.nvim_buf_is_valid(bufnr) then
            local lastused = vim.fn.getbufinfo(bufnr)[1].lastused
            table.insert(buffers, {
                bufnr = bufnr,
                lastused = lastused,
                name = vim.api.nvim_buf_get_name(bufnr)
            })
        end
    end
    
    -- Sort by last used time (oldest first)
    table.sort(buffers, function(a, b)
        return a.lastused < b.lastused
    end)
    
    return buffers
end

-- Function to strictly enforce 4 buffer limit
local function enforce_buffer_limit()
    local buffers = get_sorted_buffers()
    
    -- If we have more than 4 buffers, remove the oldest ones
    while #buffers > 4 do
        local oldest = buffers[1]
        -- Force remove the buffer
        vim.cmd(string.format('silent! bwipeout! %d', oldest.bufnr))
        -- Remove from our list
        table.remove(buffers, 1)
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup('StrictBufferLimit', { clear = true })
    
    -- Enforce limit whenever a new buffer is added
    vim.api.nvim_create_autocmd({'BufEnter', 'BufAdd', 'BufNew', 'BufNewFile'}, {
        group = group,
        callback = function()
            -- Use vim.schedule to ensure buffer is fully loaded
            vim.schedule(function()
                enforce_buffer_limit()
            end)
        end
    })

    -- Also enforce on file open
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function()
            vim.schedule(function()
                enforce_buffer_limit()
            end)
        end
    })
end

M.setup()
