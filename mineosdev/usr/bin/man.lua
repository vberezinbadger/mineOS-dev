-- man: view manual pages on things --

local args, _ = shell.parse(...)

if #args < 1 then
  return print("What manual page do you want?\nFor example, try `man shell`.")
end

if not fs.exists("/usr/man/" .. args[1]) then
  return print("No manual entry for " .. args[1])
end

local page = "/usr/man/" .. args[1]
local less = loadfile("/bin/less.lua")

less(page, "--wrap")
