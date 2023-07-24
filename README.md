
# nvim-cubby: A Cubby Plugin for Neovim

[Cubby](https://github.com/jwvictor/cubby) is an open-source "blob" storage, management, and publishing tool. It's end-to-end encrypted, built for command-line users, and has a wide range of use cases, including:

- Storing config files, cryptographic secrets, or passwords, which can sync to many machines
- Storing notes and to-do lists 
- Sharing data, with individuals or publicly
- Blogging / publishing using Markdown

`nvim-cubby` is a Neovim plugin that allows users to interact with Cubby directly from within Neovim.

## Usage

### Viewing and editing 

Cubby blobs are accessed by colon-delimited keys, like `blog:hello-cubby`. To edit a Cubby blob, simply run the command `:CubbyGet <key>` in Neovim. This will open the body of the blob in a new buffer. 

You can edit the blob, and then commit your changes by running `:CubbySave`. If you don't want to save your changes, simply discard the blob (i.e. `:q!` or `<leader>x` or similar).

### Listing blobs

To view a `cubby list`, use the `:CubbyList` command.

### Creating blobs

To quickly create a new blob, you can use `:CubbyPut <key> [<type>]`. For example, `:CubbyPut home:some-notes markdown` or `:CubbyPut home:hello-world` (the type is optional).

Note that many of the advanced options in `cubby put` are not available -- if you want to use more of the available options, you can always invoke the `cubby` CLI, e.g. `:!cubby put ...`. The `:CubbyPut` command is intended more as a quick shortcut. 

### User settings

Set plugin settings using `:CubbySet <config key> <value>`. Available settings include:

- `OpenWith` (default: `enew`): specifies the `vim` command to use when opening a new buffer for Cubby output (e.g. with `:CubbyList` or `:CubbyGet`). Example: `:CubbySet OpenWith vnew` would cause the plugin to open Cubby content in a vertical split buffer. By default, it opens a new full-screen buffer.

### Key mappings

You can add a key mapping to load `:CubbyList`. For example, in NvChad, you add this to your `~/.config/nvim/lua/custom/mappings.lua`:

```
    ["<leader>cb"] = { "<cmd> CubbyList <CR>", "Show Cubby listing", opts = { nowait = true } },
```

## Security benefits

Some users of Cubby -- particularly engineers at security-conscious technology firms -- are fully aware that they have spyware scanning their filesystem at all times; in such a situation, infosec demands assuming that any file on the filesystem is an open conversation between the user, the computer, and the employer. If you don't want your employer to see it, it can't be a file, even for a fleeting moment. 

One of the benefits of `nvim-cubby` is that the Cubby blob data is never stored in a file -- only in RAM. It would take a system beyond the sophistication most firms will deploy to compromise this setup. Just be sure, if you're in this situation, to not store the encryption passphrase used in plaintext anywhere -- instead, set it in your current shell using environment variables (although be sure your shell history is not enabled).

> "Only the paranoid survive." -Andy Grove
