-- Archiving utility. Might work. --

local args, options = shell.parse(...)

local unpack = options.u or options.unpack or false
local pack = options.p or options.pack or false

local acv = require("archive")

local usage = [[acv: Archive Utility (c) 2020 Ocawesome101 under the MIT license.
usage: acv <operation> SOURCE DESTINATION
operations:
  -p --pack        Pack all files in the specified directory into a single archive.
  -u --unpack      Unpack an archive to the specified directory.
]]

if (unpack and pack) or #args < 2 or (not pack and not unpack) then
  return print(usage)
end

local src = shell.resolve(args[1])
local dest = args[2]
if dest:sub(1, 1) ~= "/" then
  dest = fs.clean(os.getenv("PWD") .. "/" .. dest)
end

if pack then
  local ok, err = acv.pack(src, dest)
  if not ok then print("acv: " .. err) end
elseif unpack then
  local ok, err = acv.unpack(src, dest)
  if not ok then print("acv: " .. err) end
end
