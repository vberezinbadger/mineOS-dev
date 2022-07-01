-- lshw: List installed hardware --

local component = require("component")

print("TYPE        ADDRESS")
local spc = 10
for addr, ctype in component.list() do
  print(ctype, (" "):rep(spc - #ctype), addr)
end
