-- openvm: run virtual OS instances inside of Open Kernel. --
-- NOTE: requires lots of RAM
local args, options = shell.parse(...)
local config = require("config")

local usage = [[OpenVM (c) 2020 Ocawesome101 under the MIT License
usage: openvm [setup|run] ...
  run [--use-external] VM_NAME:   Launches VM_NAME in OpenVM. If --use-external is specified, will look for a second screen and GPU.
  setup ROOTFS PATH NAME:         Sets up a new virtual machine with name NAME, extracting the ROOTFS archive to PATH
]]

if #args < 1 or options.help then
  return print(usage)
end

##include lib/sandbox.lua

local instances = config.load("/usr/share/openvm.cfg")
if args[1] == "run" then
  local VM_INST = args[2]
  if not instances[VM_INST] then
    return false, print("openvm: Invalid instance ID")
  end
  components = config.load(instances[VM_INST].cfg_path)
  local ok, err = loadfile("/usr/share/openvm/machine.lua", "t", sandbox)
  if not ok then
    return false, print("error " .. err .. " loading machine.lua")
  end
  local s, r = pcall(ok)
  if not s then
    return print("error: " .. err)
  end
end
