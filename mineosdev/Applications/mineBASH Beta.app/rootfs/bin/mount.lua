-- mount: get fs mounts / mount filesystems --

local args, options = shell.parse(...)

local devfs = require("devfs")
local text = require("text")

local usage = [[mount (c) 2020 Ocawesome101 under the MIT license.
usage: mount /dev/fsX /path
   or: mount -h, --help
]]

if #args < 1 then
  local mts = fs.mounts()
  local longestPath = 0
  local longestLabel = 0
  for k,v in pairs(mts) do
    if #v.path > longestPath then
      longestPath = #v.path
    end
    if v.label and #v.label > longestLabel then
      longestLabel = #v.label
    end
  end
  for k,v in pairs(mts) do
    print(text.padRight(v.address:sub(1, 8) .. " on " .. v.path, longestLabel + longestPath) .. (fs.get(v.path).isReadOnly() and " (ro)" or " (rw)") .. (" \"" .. (v.label or v.address) .. "\""))
  end
  return
end

local dfs = args[1]
local mtpath = (args[2] and shell.resolve(args[2])) or "/mnt/"
local addr = devfs.getAddress(dfs)

if not fs.exists(dfs) then
  return print("mount: " .. mtpath .. ": special device " .. dfs .. " does not exist")
end

if not fs.exists(mtpath) then
  fs.makeDirectory(mtpath)
end

local ok, err = fs.mount(addr, mtpath)
if not ok then
  print("mount: " .. err)
end
