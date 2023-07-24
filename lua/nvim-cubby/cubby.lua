


local io = require("io")
local json = require("nvim-cubby.json")

-- Creates an object for the module.
local M = {}

local buffer_number = -1
local cubby_buffers = {}

-- Open a new buffer
local function open_buffer()
    if true or buffer_number == -1 then
        -- vim.api.nvim_command('botright vnew')
        vim.api.nvim_command('enew')
        buffer_number = vim.api.nvim_get_current_buf()
        local relbuf = buffer_number
        vim.api.nvim_buf_attach(buffer_number, false, {on_detach=function(...) cubby_buffers[relbuf] = nil end})
    end
end

-- Translate filetype from Cubby format to vim
local function filetype_to_vim(ft)
  if ft == "markdown" then
    return "markdown"
  end
  if ft == "python" then
    return "python"
  end
  -- Default to returning the Cubby type name
  return ft
end

-- Save active Cubby buffer
local function cubby_save()
  local cur_buf = vim.api.nvim_get_current_buf()
  local key = cubby_buffers[cur_buf]
  if key == nil then
    print("Not a Cubby buffer :-/")
  else
    print("Saving to Cubby: " .. key)
    local lines_dat = vim.api.nvim_buf_get_lines(cur_buf, 0, -1, true)
    -- vim.api.nvim_buf_delete(cur_buf, {force = true})
    local f = io.popen("cubby set \"" .. key .. "\"", "w")
    f:write(table.concat(lines_dat, "\n"))
    f:close()
  end
end

-- Check Cubby is available on path
local function cubby_check()
  local cmd = "cubby version"
  local handle = io.popen(cmd)
  if handle == nil then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result ~= nil and string.len(result) > 0
end

-- List Cubby blobs
local function cubby_list()
  local cmd = "cubby list"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

local function cubby_put(key, blob_type)
  local cmd = "cubby put \"" .. key .. "\" 2> /dev/null"
  if blob_type ~= nil then
    cmd = "cubby put -T " .. blob_type .. " \"" .. key .. "\" 2> /dev/null"
  end
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Get a Cubby blob in a new buffer
local function cubby_get(key)
  -- popen out to cubby cli
  local cmd = "cubby get -V=stdout \"" .. key .. "\" 2>/dev/null"
  local cmd_meta = "cubby get -V=stdout -b=false \"" .. key .. "\" 2>/dev/null"
  -- print("Cmd: " .. cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

local function cubby_get_set_filetype(key)
  local cmd_meta = "cubby get -V=stdout -b=false \"" .. key .. "\" 2>/dev/null"
  local handle_meta = io.popen(cmd_meta)
  local result_meta = string.gsub(handle_meta:read("*a"), "[\n\r\t]", "")
  if result_meta == nil then
    return nil
  elseif string.len(result_meta) < 1 then
    handle_meta:close()
    return nil
  end
  handle_meta:close()
  local metadata = json.parse(result_meta)
  vim.api.nvim_command('set filetype=' .. filetype_to_vim(metadata["type"]))
  return result
end

-- Accessor functions (public)
function M.get(key)
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  local res = cubby_get(key)
  if res == nil then
    print("No blob found with key: " .. key)
    return
  end
  open_buffer()
  cubby_buffers[vim.api.nvim_get_current_buf()] = key
  local lines = {}
  for s in res:gmatch("([^\n]*)\n?") do
    table.insert(lines, s)
  end
  vim.api.nvim_buf_set_lines(buffer_number, 0, -1, true, lines)
  cubby_get_set_filetype(key)
end

function M.save()
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  cubby_save()
end

function M.put(key, blob_type)
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  local res = cubby_put(key, blob_type)
  if res == nil or string.len(res) < 1 then
    print("Invalid key for Cubby put.")
    return
  end
end


function M.list()
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  open_buffer()
  local txt = cubby_list()
  local lines = {}
  for s in txt:gmatch("([^\n]*)\n?") do
    table.insert(lines, s)
  end
  vim.api.nvim_buf_set_lines(buffer_number, 0, -1, true, lines)
end

return M

