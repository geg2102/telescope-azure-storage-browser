local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
    error "This extension requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)"
end

local az_actions = require "telescope._extensions.az_storage.actions"
local az_finders = require "telescope._extensions.az_storage.finders"
local az_picker = require "telescope._extensions.az_storage.picker"
local az_config = require "telescope._extensions.az_storage.config"

local az_storage = function(opts)
    opts = opts or {}
    local defaults = (function()
        return vim.deepcopy(az_config.values)
    end)()

    if az_config.values.mappings then
        defaults.attach_mappings = function(prompt_bufnr, map)
            if az_config.values.attach_mappings then
                az_config.values.attach_mappings(prompt_bufnr, map)
            end
            for mode, tbl in pairs(az_config.values.mappings) do
                for key, action in pairs(tbl) do
                    map(mode, key, action)
                end
            end
            return true
        end
    end

    if opts.attach_mappings then
        local opts_attach = opts.attach_mappings
        opts.attach_mappings = function(prompt_bufnr, map)
            defaults.attach_mappings(prompt_bufnr, map)
            return opts_attach(prompt_bufnr, map)
        end
    end
    local popts = vim.tbl_deep_extend("force", defaults, opts)
    az_picker.blobs(popts)
end

return telescope.register_extension {
    setup = az_config.setup,
    exports = {
        az_storage = az_storage,
        actions = az_actions,
        finder = az_finders,
        _picker = az_picker,
    },
}
