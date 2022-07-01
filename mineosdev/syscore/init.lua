-- This script just loads the kernel. That's all it does. You can go now. --

-- Only edit this table! --
local flags = {
  init = "/sbin/init.lua",
  runlevel = 2, -- Runlevel the system should attempt to reach
  disableLogging = true, -- Enable this option if you're running from a read-only FS or you want faster boot. Disable if you want system logs (i.e. for debugging) and aren't running from a ROFS
  verbose = true, -- Whether to log boot or not, otherwise you will get a black screen until the shell is loaded. Disabling this does seem to improve boot times.
  processTimeout = 0.05 -- The timeout passed to computer.pullSignal in the scheduler. This has a fairly direct impact on performance.
}

-- Leave the rest alone. --

local addr, invoke = component.invoke(component.list("eeprom")(), "getData"), component.invoke
local p = computer.pullSignal

local function loadfile(file)
  local handle = assert(invoke(addr, "open", file))
  local buffer = ""
  repeat
    local data = invoke(addr, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  invoke(addr, "close", handle)
  return load(buffer, "=" .. file, "bt", _G)
end

local ok, err = loadfile("/boot/kernel.lua")
if not ok then
  error(err)
end

ok(flags)

while true do
  local sig, _, n = p()
  if sig == "key_down" then
    if string.char(n) == "r" then
      computer.shutdown(true)
    end
  end
end
