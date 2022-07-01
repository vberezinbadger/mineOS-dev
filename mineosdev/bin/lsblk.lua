-- lsblk: list installed filesystems --

local args, options = shell.parse(...)

local component = require("component")
local devfs = require("devfs")

local bytes = options.b or options.bytes or false

local mts = fs.mounts()

local function findMount(a)
  for k,v in pairs(mts) do
    if v.address == a then
      return v.path
    end
  end
  return ""
end

print("NAME                 SIZE    RO    MOUNTPOINT")

for addr, _ in component.list("filesystem") do
  local size = component.invoke(addr, "spaceTotal")
  if bytes or size < 1024 then
    size = tostring(size) .. "B"
  elseif size < 1024*1024 then
    size = tostring(math.ceil(size/1024)) .. "K"
  else
    size = tostring(math.ceil(size/1024/1024)) .. "M"
  end
  local name = component.invoke(addr, "getLabel")
  name = (name ~= "" and name) or addr:sub(1,6)
  local mtpath = findMount(addr)
  local ro = tostring(component.invoke(addr, "isReadOnly"))
  while #name < 20 do
    name = name .. " "
  end
  while #size < 7 do
    size = size .. " "
  end
  while #ro < 5 do
    ro = ro .. " "
  end
  print(name, size, ro, mtpath)
end
