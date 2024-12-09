# telescope-az-storage.nvim

A Telescope extension that allows you to search through azure storage containers and blobs directly from editor.
The code and idea are heavily inspired by the fantastic extension
[telescope-file-browser.nvim](https://github.com/nvim-telescope/telescope-file-browser.nvim).
Effectively, the extension aims to capture the most basic functionality of
file-browser, but apply it to azure storage blobs.

## Features

- Browse Azure Storage containers and blobs
- Save a blob name to register for pasting (`"` register by default)
- Fuzzy search through blob names
- Upload local files to Azure Storage
- Delete blobs/directories 

## Requirements

- Neovim >= 0.10.0
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'geg2102/telescope-azure-storage-browser',
  requires = {
    {'nvim-telescope/telescope.nvim'},
    {'nvim-lua/plenary.nvim'},
  }
}
```

## Setup

```lua
require('telescope').load_extension('az_storage')
```

## Configuration

Configure the extension in your Telescope config:

```lua
require('telescope').setup {
  extensions = {
    az_storage = {
        account_name = "your_account_name_here"
    }
  }
}
```

## Usage

### Browse Containers

```vim
:Telescope az_storage 
```

Lists all containers in your Azure Storage account. Press `<CR>` to browse blobs inside a container.
Keep pressing `<CR>` until you selected the full path to the blob and it will be saved to register, or use `<BS>` to go up a directory. 
When in a directory, use `<C-u>` to upload a file. When selecting a blob or directory use `<C-d>` to delete. 

### Key Mappings

Default mappings in the picker:

- `<CR>`: Traverse down directory tree/save the selected blob to register.
- `<BS>`: Traverse up directory tree
- `<C-d>`: Delete selected blob/directory
- `<C-u>`: Upload file to current directory

## Note

Ensure you're logged into Azure CLI:
```bash
az login
```

Set your default subscription if needed:
```bash
az account set --subscription <subscription-id>
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
