-- pkill: kill processes --

local args, options = shell.parse(...)

local informedKill = options.inform or options.i or false

if #args < 1 then
  return print("usage: pkill [-i|--inform] PID")
end

local event = require("event")

if informedKill then
  event.push("kill", tonumber(args[1])) -- We might as well let the process know if it's being killed, right?
  coroutine.yield() -- Let it process
end

local ok, err = os.kill(tonumber(args[1]))

if not ok then
  return print(err)
end

coroutine.yield()
