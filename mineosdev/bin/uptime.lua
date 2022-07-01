-- uptime: system uptime --

local computer = require("computer")

print("up about " .. tostring(math.floor(computer.uptime())) .. "s")
