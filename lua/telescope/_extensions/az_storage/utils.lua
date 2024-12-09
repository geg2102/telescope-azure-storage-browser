local utils = {}
local Job = require('plenary.job')
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local conf = require('telescope.config').values
local action_state = require('telescope.actions.state')
local actions = require('telescope.actions')

utils.select_container = function(opts, on_container_selected)
    local container_list = {}

    Job:new({
        command = 'az',
        args = { 'storage', 'container', 'list', '--account-name', opts.account_name, '--output', 'json' },
        on_exit = function(j, return_val)
            if return_val == 0 then
                local result = table.concat(j:result(), '')
                local containers = vim.json.decode(result)
                for _, container in ipairs(containers) do
                    table.insert(container_list, container.name)
                end
            else
                print('Failed to list containers')
            end
            vim.schedule(function()
                if #container_list == 0 then
                    print('No containers found')
                    return
                end

                pickers.new({}, {
                    prompt_title = 'Select a container',
                    finder = finders.new_table {
                        results = container_list,
                    },
                    sorter = conf.generic_sorter({}),
                    attach_mappings = function(prompt_bufnr, map)
                        actions.select_default:replace(function()
                            local selection = action_state.get_selected_entry()
                            local choice = selection.value
                            actions.close(prompt_bufnr)
                            on_container_selected(choice)
                        end)
                        return true
                    end,
                }):find()
            end)
        end
    }):start()
end


utils.refresh_picker = function(container_name, opts, prefix)
    -- Re-run the picker with updated options
    require('telescope._extensions.az_storage.picker').blobs({
        account_name = opts.account_name,
        container_name = container_name,
        prefix = prefix,
    })
end

return utils
