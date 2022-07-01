-- free: List total used memory --

local args, options = shell.parse(...)

local human = options.h or false

local computer = require("computer")

local free = computer.freeMemory()
local total = computer.totalMemory()
local used = total - free

if human then
  free = tostring(math.floor(free / 1024)) .. "K"
  total = tostring(math.floor(total / 1024)) .. "K"
  used = tostring(math.floor(used / 1024)) .. "K"
end

print("Total:", total)
print("Used:", used)
print("Free:", free)
