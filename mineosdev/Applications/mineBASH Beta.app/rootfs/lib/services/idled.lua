-- Restart the shell/login if they terminate --

local computer = require("computer")

local program = "/bin/sh.lua"

if computer.runlevel() >= 2 then
  program = "/bin/login.lua"
end

while true do
  coroutine.yield()
  local t = os.tasks()
  local running = false
  for k,v in pairs(t) do
    if os.info(v).name == program then
      running = true
    end
  end
  if not running then
    local ok, err = loadfile(program)
    if not ok then
      print(err)
      os.sleep(5)
    end
    os.spawn(ok, program)
    coroutine.yield()
  end
end
