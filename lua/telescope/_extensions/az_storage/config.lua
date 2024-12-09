local config = {}

config.values = {
  account_name = 'your_default_account_name',
  mappings = {
    ['i'] = {
      -- Your mappings
    },
    ['n'] = {
      -- Your mappings
    },
  },
}

config.setup = function(opts)
  config.values = vim.tbl_extend('force', config.values, opts or {})
end

return config
