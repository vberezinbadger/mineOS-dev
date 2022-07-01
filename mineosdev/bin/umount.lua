-- umount: unmount filesystems --

local args, options = shell.parse(...)

if #args < 1 then
  print("umount: bad usage")
  print("Try 'umount --help' for more information.")
  return
end

local usage = [[umount (c) 2020 Ocawesome101 under the MIT License.
Usage: umount PATH
]]

local mtpath = shell.resolve(args[1])

if not fs.exists(mtpath) then
  return print("umount: " .. args[1] .. ": no mount point specified")
end

local ok, err = fs.unmount(mtpath)
if not ok then
  return print(err)
end
