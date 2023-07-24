-- Imports the plugin's additional Lua modules.

local cubby = require("nvim-cubby.cubby")

-- Creates an object for the module. All of the module's
-- functions are associated with this object, which is
-- returned when the module is called with `require`.
local M = {}

M.cubby_get = cubby.get
M.cubby_save = cubby.save
M.cubby_list = cubby.list
M.cubby_put = cubby.put
M.cubby_set_option = cubby.set_option

return M
