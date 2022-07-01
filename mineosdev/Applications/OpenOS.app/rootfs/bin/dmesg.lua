local event = require("event")
local tty = require("tty")

local args = {...}
local gpu = tty.gpu()
local interactive = io.output().tty
local color, isPal, evt
if interactive then
  color, isPal = gpu.getForeground()
end
io.write("Press 'Ctrl-C' to exit\n")
pcall(function()
  repeat
    if #args > 0 then
      evt = table.pack(event.pullMultiple("interrupted", table.unpack(args)))
    else
      evt = table.pack(event.pull())
    end
    if interactive then gpu.setForeground(0xac1c27) end
    io.write("[" .. os.date("%T") .. "] ")
    if interactive then gpu.setForeground(0x2eac63) end
    io.write(tostring(evt[1]) .. string.rep(" ", math.max(10 - #tostring(evt[1]), 0) + 1))
    if interactive then gpu.setForeground(0xd5d64e) end
    io.write(tostring(evt[2]) .. string.rep(" ", 37 - #tostring(evt[2])))
    if interactive then gpu.setForeground(_G.MINEOS_INTEGRATION.COLORS.FOREGROUND) end
    if evt.n > 2 then
      for i = 3, evt.n do
        io.write("  " .. tostring(evt[i]))
      end
    end
    
    io.write("\n")
  until evt[1] == "interrupted"
end)
if interactive then
  gpu.setForeground(color, isPal)
end

