local status_ok, pickers = pcall(require, 'telescope.pickers')
if not status_ok then
    error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end

local status_ok_finders, finders = pcall(require, 'telescope.finders')
if not status_ok_finders then
    error("This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)")
end
local conf = require('telescope.config').values
local Job = require('plenary.job')
local az_actions = require('telescope._extensions.az_storage.actions')
local az_utils = require('telescope._extensions.az_storage.utils')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')

local az_picker = {}

az_picker.blobs = function(opts)
    opts = opts or {}
    local proceed_with_blobs = function(container_name)
        if not container_name then
            print('No container selected')
            return
        end

        local prefix = opts.prefix or ''

        -- Fetch blobs asynchronously, then create the picker
        local results = {}
        Job:new({
            command = 'az',
            args = {
                'storage', 'blob', 'list',
                '--account-name', opts.account_name,
                '--container-name', container_name,
                '--prefix', prefix,
                '--delimiter', '/',
                '--output', 'json'
            },
            on_exit = function(j, return_val)
                if return_val == 0 then
                    local result = table.concat(j:result(), '')
                    local blobs_info = vim.json.decode(result)

                    if blobs_info then
                        for _, item in ipairs(blobs_info) do
                            local blob_name = item.name
                            if blob_name:sub(-1) == '/' then
                                -- This is a directory
                                table.insert(results, {
                                    name = blob_name,
                                    display = blob_name,
                                    ordinal = blob_name,
                                    type = 'directory',
                                    container_name = container_name,
                                    prefix = blob_name,
                                    opts = opts,
                                })
                            else
                                -- This is a blob
                                table.insert(results, {
                                    name = blob_name,
                                    display = blob_name,
                                    ordinal = blob_name,
                                    type = 'blob',
                                    container_name = container_name,
                                    prefix = prefix,
                                    opts = opts,
                                })
                            end
                        end
                    end

                    -- Schedule the picker creation on the main thread
                    vim.schedule(function()
                        if #results == 0 then
                            print('No blobs found')
                            return
                        end

                        pickers.new(opts, {
                            prompt_title = 'Azure Storage Blobs',
                            finder = finders.new_table {
                                results = results,
                                entry_maker = function(entry)
                                    return {
                                        value = entry.name,
                                        display = entry.display,
                                        ordinal = entry.ordinal,
                                        type = entry.type,
                                        container_name = entry.container_name,
                                        prefix = entry.prefix,
                                        opts = { -- Explicitly set the options
                                            account_name = opts.account_name,
                                            container_name = entry.container_name,
                                            prefix = entry.prefix or ''
                                        },
                                        name = entry.name,
                                    }
                                end,
                            },
                            sorter = conf.generic_sorter(opts),
                            account_name = opts.account_name,
                            container_name = opts.container_name,
                            prefix = opts.prefix or '',
                            attach_mappings = function(prompt_bufnr, map)
                                local function handle_selection()
                                    local selection = action_state.get_selected_entry()
                                    local opts = selection.opts
                                    actions.close(prompt_bufnr)

                                    if selection.type == 'directory' then
                                        az_picker.blobs({
                                            account_name = opts.account_name,
                                            container_name = selection.container_name,
                                            prefix = selection.name,
                                        })
                                    else
                                        local blob_path = selection.container_name .. '/' .. selection.name
                                        vim.fn.setreg('"', blob_path)
                                        print("Selected blob path saved to register: " .. blob_path)
                                    end
                                end

                                actions.select_default:replace(handle_selection)

                                map('i', '<C-u>', function()
                                    local current_picker = action_state.get_current_picker(prompt_bufnr)
                                    local current_selection = action_state.get_selected_entry()

                                    -- Use the current directory's prefix instead of the selection's prefix
                                    local current_prefix = current_picker.prefix or ''

                                    local upload_opts = {
                                        account_name = current_selection.opts.account_name,
                                        container_name = current_selection.container_name,
                                        prefix = current_prefix -- Use the current directory's prefix
                                    }

                                    az_actions.upload_blob(prompt_bufnr, upload_opts, current_selection)
                                end)
                                map('i', '<C-d>', function()
                                    local selection = action_state.get_selected_entry()
                                    if selection.type == 'directory' then
                                        az_actions.delete_directory(prompt_bufnr)
                                    else
                                        az_actions.delete_blob(prompt_bufnr)
                                    end
                                end)

                                map('i', '<BS>', function()
                                    local selection = action_state.get_selected_entry()
                                    local opts = selection.opts

                                    -- Get the current prefix
                                    local current_prefix = selection.prefix or ''

                                    -- Remove the trailing slash if present
                                    if current_prefix:sub(-1) == '/' then
                                        current_prefix = current_prefix:sub(1, -2)
                                    end

                                    -- Remove the last directory from the prefix to go up one level
                                    local parent_prefix = current_prefix:gsub('[^/]+/?$', '')

                                    actions.close(prompt_bufnr)

                                    if parent_prefix == '' then
                                        -- Go back to container selection
                                        az_utils.select_container(opts, function(container_name)
                                            az_picker.blobs({
                                                account_name = opts.account_name,
                                                container_name = container_name,
                                            })
                                        end)
                                    else
                                        -- Refresh the picker with the parent prefix
                                        az_picker.blobs({
                                            account_name = opts.account_name,
                                            container_name = selection.container_name,
                                            prefix = parent_prefix,
                                        })
                                    end
                                end)

                                return true
                            end,
                        }):find()
                    end)
                else
                    vim.schedule(function()
                        print('Failed to list blobs')
                    end)
                end
            end
        }):start()
    end

    if opts.container_name then
        proceed_with_blobs(opts.container_name)
    else
        az_utils.select_container(opts, proceed_with_blobs)
    end
end

return az_picker
