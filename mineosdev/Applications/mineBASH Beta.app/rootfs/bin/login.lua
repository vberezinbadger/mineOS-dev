-- Login screen --

local users = require("users")

-- e-z config :P
local cls = true

for _,t in pairs(os.tasks()) do
  if os.info(t).name == "/bin/sh.lua" then
    return print("Login: this user is already in the session!")
  end
end

while true do
  io.write("Login: ")
  local name = read()
  local ok, err = users.login(name)
  if not ok then
    print(err)
  else
    local ok, err = loadfile("/bin/sh.lua")
    if not ok then
      error(err)
    end
    os.spawn(ok, "/bin/sh.lua")
    coroutine.yield()
    local shell = true
    while shell do
      shell = false
      local t = os.tasks()
      for k,v in pairs(t) do
        if os.info(v).name == "/bin/sh.lua" then
          shell = true
        end
      end
      coroutine.yield()
    end
    if cls then
      local w,h = gpu.getResolution()
      gpu.fill(1, 1, w, h, " ")
      gpu.setCursor(1, 1)
    end
  end
end
