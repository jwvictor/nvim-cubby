


local io = require("io")
local json = require("nvim-cubby.json")

-- Creates an object for the module.
local M = {}

local cubby_buffers = {}
local cubby_list_buffers = {}

local user_options = {}

local OpenWith = "OpenWith"
local CryptoPass = "CryptoPass"

local function buffer_readonly(buf)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local function buffer_readonly_disable(buf)
  vim.api.nvim_buf_set_option(buf, "readonly", false)
  vim.api.nvim_buf_set_option(buf, "modifiable", true)
end

local function user_option_set(opt_name, opt_value, arg)
  if opt_value == "false" then
    user_options[opt_name] = false
    print("Setting " .. opt_name .. " to false")
  elseif opt_value == "true" then
    user_options[opt_name] = true
    print("Setting " .. opt_name .. " to true")
  else
    local s = opt_value
    for i, x in ipairs(arg) do
      s = s .. " " .. x
    end
    user_options[opt_name] = s
    print("Setting " .. opt_name .. " to " .. s)
  end
end

-- Open a new buffer
local function open_buffer()
  local open_cmd = user_options[OpenWith];
  if open_cmd == nil then
    open_cmd = 'enew'
  end
  vim.api.nvim_command(open_cmd)
  local buffer_number = vim.api.nvim_get_current_buf()
  -- print("Using buffer " .. buffer_number)
  local relbuf = buffer_number
  vim.api.nvim_buf_attach(buffer_number, false, {on_detach=function(...) if cubby_buffers[relbuf] ~= nil then cubby_buffers[relbuf] = nil end end})
end

local function open_buffer_list()
  local open_cmd = user_options[OpenWith];
  if open_cmd == nil then
    open_cmd = 'enew'
  end
  vim.api.nvim_command(open_cmd)
  local buffer_number = vim.api.nvim_get_current_buf()
  -- print("Using buffer " .. buffer_number)
  local relbuf = buffer_number
  vim.api.nvim_buf_attach(buffer_number, false, {on_detach=function(...) if cubby_buffers[relbuf] ~= nil then cubby_list_buffers[relbuf] = nil; buffer_readonly_disable(relbuf) end end})
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

-- Go to line in Cubby listing
local function cubby_go()
  local cur_buf = vim.api.nvim_get_current_buf()
  local ids = cubby_list_buffers[cur_buf]
  if ids == nil then
    print("This buffer is not a Cubby list.")
    return
  end
  local cursor = vim.api.nvim_win_get_cursor(0)
  local r = cursor[1]
  -- print("Current row: " .. r)
  --print("Current ids: " .. table.tostring(ids))
  -- print("Current ids len: " .. #ids)
  if r <= #ids then
    local id = ids[r]
    -- print(id)
    M.get(id)
  end
end

-- If the user set an override crypto key, use it
local function maybe_cryptopass_command(cmd)
  if user_options[CryptoPass] ~= nil then
    return "CUB_CRYPTO_SYMMETRIC_KEY=" .. user_options[CryptoPass] .. " " .. cmd
  else
    return cmd
  end
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
    local cmd = "cubby set \"" .. key .. "\" 2>/dev/null"
    cmd = maybe_cryptopass_command(cmd)
    local f = io.popen(cmd, "w")
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
  local cmd = "cubby list -J"
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  if result == nil then
    return nil
  end
  local parsed = json.parse(result)
  return parsed
  -- return result
end

local function cubby_put(key, blob_type)
  local cmd = "cubby put \"" .. key .. "\" 2> /dev/null"
  if blob_type ~= nil then
    cmd = "cubby put -T " .. blob_type .. " \"" .. key .. "\" 2> /dev/null"
  end
  cmd = maybe_cryptopass_command(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

-- Get a Cubby blob in a new buffer
local function cubby_get(key)
  -- popen out to cubby cli
  local cmd = "cubby get -V=stdout \"" .. key .. "\" 2>/dev/null"
  cmd = maybe_cryptopass_command(cmd)
  -- print("Cmd: " .. cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result
end

local function cubby_get_set_filetype(key)
  local cmd_meta = "cubby get -V=stdout -b=false \"" .. key .. "\" 2>/dev/null"
  cmd_meta = maybe_cryptopass_command(cmd_meta)
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

local function current_buffer_set_nofile()
  vim.api.nvim_command('set bt=nofile')
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
  vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, -1, true, lines)
  cubby_get_set_filetype(key)
  current_buffer_set_nofile()
end

function table.slice(tbl, first, last, step)
  local sliced = {}

  for i = first or 1, last or #tbl, step or 1 do
    sliced[#sliced+1] = tbl[i]
  end

  return sliced
end

function M.set_option(...)
  local arg = {...}
  local key = arg[1]
  local value = arg[2]
  local varargs = table.slice(arg, 3, #arg, 1)
  user_option_set(key, value, varargs)
end

function M.save()
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  cubby_save()
end

function M.go()
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  cubby_go()
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

local function render_list(data, lines, ids, n_indents0)
  local n_indents = 0
  if n_indents0 ~= nil then
    n_indents = n_indents0
  end
  local s = ""
  for i = 1, n_indents do
    s = s .. ". "
  end
  s = s .. data["title"] -- .. " - " .. data["id"]
  table.insert(lines, s)
  table.insert(ids, data["id"])
  if data["children"] ~= nil then
    for i, v in ipairs(data["children"]) do
      render_list(v, lines, ids, n_indents+1)
    end
  end
end


function M.list()
  if not cubby_check() then
    print("Cubby is not installed in PATH - please see cubbycli.com for instructions.")
    return
  end
  open_buffer_list()
  local dat = cubby_list()
  local lines = {}
  local ids = {}
  render_list(dat, lines, ids)
  local cur_buf = vim.api.nvim_get_current_buf()
  cubby_list_buffers[cur_buf] = ids
  vim.api.nvim_buf_set_lines(cur_buf, 0, -1, true, lines)
  buffer_readonly(cur_buf)
  current_buffer_set_nofile()
end

return M

