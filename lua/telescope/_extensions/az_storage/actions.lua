local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local Job = require('plenary.job')
local az_utils = require('telescope._extensions.az_storage.utils')

local actions_module = {}


-- Function to upload a blob
actions_module.upload_blob = function(prompt_bufnr, opts, selection)
    -- Add debug logging
    if not opts then
        print("Warning: opts is nil, attempting to get from picker")
        local picker = action_state.get_current_picker(prompt_bufnr)
        if picker and picker.opts then
            opts = {
                account_name = picker.opts.account_name,
                container_name = picker.opts.container_name,
                prefix = picker.opts.prefix or ''
            }
        else
            print("Error: Could not get picker options")
            return
        end
    end

    -- Validate required options
    if not opts.account_name or not opts.container_name then
        print("Error: Missing required options (account_name or container_name)")
        return
    end

    local prefix = opts.prefix or ''
    local container_name = opts.container_name
    actions.close(prompt_bufnr)

    -- Prompt user for file and blob name
    local file_path = vim.fn.input('Path to local file: ', '', 'file')
    if file_path == '' then return end
    local blob_name = vim.fn.input('Blob name (relative to current directory): ', '')
    if blob_name == '' then return end

    local full_blob_name = prefix .. blob_name

    Job:new({
        command = 'az',
        args = {
            'storage', 'blob', 'upload',
            '--account-name', opts.account_name,
            '--container-name', container_name,
            '--name', full_blob_name,
            '--file', file_path
        },
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    print('Uploaded blob: ' .. full_blob_name)
                else
                    print('Failed to upload blob: ' .. full_blob_name)
                end
            end)
        end
    }):start()
end

-- Function to delete a blob
actions_module.delete_blob = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local container_name = selection.container_name
    local blob_name = selection.name
    local opts = selection.opts
    actions.close(prompt_bufnr)

    local confirm = vim.fn.confirm('Delete blob "' .. blob_name .. '"?', '&Yes\n&No', 2)
    if confirm ~= 1 then return end

    Job:new({
        command = 'az',
        args = {
            'storage', 'blob', 'delete',
            '--account-name', opts.account_name,
            '--container-name', container_name,
            '--name', blob_name,
            -- '--yes'
        },
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    print('Deleted blob: ' .. blob_name)
                    -- Refresh the picker after deletion
                    az_utils.refresh_picker(container_name, opts, selection.prefix)
                else
                    print('Failed to delete blob: ' .. blob_name)
                end
            end)
        end
    }):start()
end

-- Function to delete a directory and its contents
actions_module.delete_directory = function(prompt_bufnr)
    local selection = action_state.get_selected_entry()
    local container_name = selection.container_name
    local prefix = selection.name
    local opts = selection.opts
    actions_module.close(prompt_bufnr)

    local confirm = vim.fn.confirm('Delete directory "' .. prefix .. '" and all its contents?', '&Yes\n&No', 2)
    if confirm ~= 1 then return end

    Job:new({
        command = 'az',
        args = {
            'storage', 'blob', 'delete-batch',
            '--account-name', opts.account_name,
            '--source', container_name,
            '--pattern', prefix .. '*',
            -- '--yes'
        },
        on_exit = function(_, return_val)
            vim.schedule(function()
                if return_val == 0 then
                    print('Deleted all blobs under: ' .. prefix)
                    -- Refresh the picker after deletion
                    az_utils.refresh_picker(container_name, opts, selection.prefix)
                else
                    print('Failed to delete blobs under: ' .. prefix)
                end
            end)
        end
    }):start()
end

return actions_module
