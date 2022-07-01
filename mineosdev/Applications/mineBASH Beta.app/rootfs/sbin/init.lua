-- mineBASH init system --

local maxRunlevel = ... or 2

local rc = {}
local runlevel = 1
local shutdown = computer.shutdown

function computer.runlevel()
  return runlevel
end

rc._VERSION = "mineBASH"

kernel.log(rc._VERSION .. " starting up " .. kernel._VERSION)

gpu.setForeground(0x00DD11)
write(rc._VERSION)
gpu.setForeground(0xFFFFFF)
write(" starting up ")
gpu.setForeground(0xFFFF00)
print(kernel._VERSION)
gpu.setForeground(0xFFFFFF)

kernel.log("init: Reading configuration from /etc/inittab")
local config = {}

local handle, err = fs.open("/etc/inittab")
if not handle then
  error("Failed to load init configuration: " .. err)
end

local data = ""
repeat
  local d = handle.read(math.huge)
  data = data .. (d or "")
until not d
handle.close()

local ok, err = load("return " .. data, "=openrc.parse-config", "bt", _G)
if not ok then
  error("Failed to parse init configuration: " .. err)
end

config = ok()

for k, v in ipairs(config.startup) do
  kernel.log("init: loading " .. v.id)
  local ok, err = loadfile(v.file)
  if not ok then
    kernel.log("init: WARNING: Failed to load " .. v.id .. ": " .. err)
    error(err, -1)
  end
  local ok, err = pcall(ok)
  if not ok then
    kernel.log("init: WARNING: " .. v.id .. " crashed: " .. err)
    error(err, -1)
  end
end

if maxRunlevel >= 2 then
  runlevel = 2
  for k,v in ipairs(config.daemons) do
    kernel.log("init: Starting service " .. v.id)
    local ok, err = loadfile(v.file)
    if not ok then
      kernel.log("init: Service " .. v.id .. " failed: " .. err)
    else
      os.spawn(ok, v.file)
    end
  end
end

kernel.setlogs(false)

while true do
  local processRunning = false
  for k,v in pairs(os.tasks()) do
    local name = os.info(v).name
    if name == "/bin/sh.lua" or name == "/bin/login.lua" then
      processRunning = true
    end
  end
  if maxRunlevel >= 2 and not processRunning then
    local ok, err = loadfile("/bin/login.lua")
    if not ok then
      error(err, -1)
    end

    os.spawn(ok, "/bin/login.lua")
  elseif not processRunning then
    kernel.log("init: Starting single-user shell")
    local ok, err = loadfile("/bin/sh.lua")
    if not ok then
      error(err, -1)
    end

    os.spawn(ok, "/bin/sh.lua")
  end
  coroutine.yield()
end
