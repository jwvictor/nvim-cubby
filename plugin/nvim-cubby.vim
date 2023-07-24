" Title:        neovim-cubby
" Description:  A plugin for Neovim to interact with the Cubby blob storage
"               system (c.f. cubbycli.com).
" Last Change:  20 July 2023
" Maintainer:   Jason Victor <https://github.com/jwvictor>

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_nvimcubby")
    finish
endif
let g:loaded_nvimcubby = 1

" Defines a package path for Lua. This facilitates importing the
" Lua modules from the plugin's dependency directory.

" JV commented these 2 lines out - bring them back if we need deps
" let s:lua_rocks_deps_loc =  expand("<sfile>:h:r") . "/../lua/nv-cubby/deps"
"exe "lua package.path = package.path .. ';" . s:lua_rocks_deps_loc . "/lua-?/init.lua'"

" Exposes the plugin's functions for use as commands in Neovim.
command! -nargs=1 CubbyGet lua require("nvim-cubby").cubby_get(<f-args>)
command! -nargs=0 CubbySave lua require("nvim-cubby").cubby_save()
command! -nargs=0 CubbyList lua require("nvim-cubby").cubby_list()
command! -nargs=* CubbyPut lua require("nvim-cubby").cubby_put(<f-args>)
" command! -nargs=* FetchTest lua require("nvim-cubby").fetch_test(<f-args>)
