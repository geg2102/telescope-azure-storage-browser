local config = require('telescope._extensions.az_storage.config')
local az_picker = require('telescope._extensions.az_storage.picker')

return require('telescope').register_extension({
    setup = config.setup,
    exports = {
        az_storage = az_picker.blobs,
    },
})
