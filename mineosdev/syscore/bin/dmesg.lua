-- dmesg: display signals --

local computer = require("computer")
local event = require("event")

while true do
  local edata = {event.pull()}
  if edata ~= {} then print(computer.uptime(), table.unpack(edata)) end
  if type(edata[3]) == "number" and string.char(edata[3]) == "q" then
    break
  end
  coroutine.yield()
end
