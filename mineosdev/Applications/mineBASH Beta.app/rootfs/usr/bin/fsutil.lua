-- Manage filesystems according the the specifications defined at https://github.com/GlobalEmpire/OpenStandards/blob/master/Filesystems/OpenUPT.md and OpenFS.md --
-- Ported from Open Kernel 1.0

local args = {...}

local component = require("component")
local computer = require("computer")
local event = require("event")
local openupt, e = require("openupt")
if not openupt then
  return print(e)
end

if #args < 1 or args[1] == "help" then
  print([[FSUtil (c) 2020 Ocawesome101 under the MIT license.
Usage: fsutil OPERATION ...
FSUtil will attempt to auto-detect unmanaged drives.
Available OPERATIONs are:
 format [mode=secure|fast]:      Format a disk with an OpenUPT partition table. If SECURE is specified, will zero the entire disk.
 mkpart START END LABEL [type]:  Add a partition from sector START to sector END.
 delpart:                        Delete a partition.
 lspart:                         List the label, type, and GUID of all partitions on a drive.
 bootloader FILE:                Write FILE to the disk as its boot loader.
 bootsector FILE:                Write FILE to sector 1 of the disk.]])
  return false
end

-- Default bootsector.
local boot_sector = [[local gpu, screen = component.list("gpu")(), component.list("screen")()
if gpu and screen then
  component.invoke(gpu, "bind", screen)
  local w,h = component.invoke(gpu, "getResolution")
  component.invoke(gpu, "fill", 1, 1, w, h, " ")
  component.invoke(gpu, "set", 1, 1, "Non-system disk or disk error. Press any key to reboot.")
  repeat
    local e = computer.pullSignal()
  until e == "key_down"
  computer.shutdown(true)
else print("Non-system disk or disk error. System halt.") end]]

print("fsutil: Detecting unmanaged drives....")
local drives = {}
local drive = ""
for addr, ctype in component.list("drive") do
  if ctype == "drive" then
    table.insert(drives, addr)
  end
end

if #drives == 0 then
  return print("fsutil: No unmanaged drives found")
end

if #drives == 1 then
  drive = component.proxy(drives[1])
end

if #drives > 1 then
  print("fsutil: Choose a drive:")
  for i=1, #drives, 1 do
    print(tostring(i) .. ". " .. drives[i]:sub(1, 6))
  end
  local c
  repeat
    local e, _, id = event.pull()
    if e == "key_down" then c = tonumber(string.char(id)) end
  until c <= #drives
  drive = component.proxy(drives[c])
end

if args[1] == "format" then
  if args[2] and args[2] ~= "mode=secure" and args[2] ~= "mode=fast" then
    print("fsutil: Unrecognized option " .. args[2])
    return false
  end
  print("WARNING: Formatting a disk will erase all currently stored data!")
  io.write("Are you sure you want to continue? [y/N]: ")
  local e, id
  repeat
    e, _, id = event.pull()
  until e == "key_down" and string.char(id) == "y" or string.char(id) == "n"
  io.write(string.char(id) .. "\n")
  if string.char(id):lower() == "n" then
    print("Operation canceled. Have a nice day.")
    return
  end
  print("Formatting " .. drive.address:sub(1, 6))
  local zero = string.char(0):rep(512)
  if args[2] and args[2] == "mode=secure" then
    io.write("Zeroing drive. This might take a while...")
    for i=1, drive.getCapacity() / 512, 1 do
      if i % 8 == 0 then
        io.write(".")
      end
      drive.writeSector(i, zero)
    end
    print("done")
  end
  io.write("Writing boot sector...")
  local b = boot_sector
  while #b < 512 do
    b = b .. " "
  end
  drive.writeSector(1, b)
  print("done.")
  return
else
  local ptable = drive.readSector(25)
  openupt.setPartitionTable(ptable)
end
if args[1] == "mkpart" then
  if not args[2] and not args[3] then
    return print("fsutil: Missing arguments. Run 'fsutil help' for help.")
  end
  io.write("Reading existing partition table...")
  local ptable = drive.readSector(25)
  openupt.setPartitionTable(ptable)
  io.write("done.\nCreating partition...")
  local start = tonumber(args[2])
  openupt.mkpart(start, tonumber(args[3]), args[5], nil, args[4] and args[4]:sub(1, 32))
  io.write("done.\nWriting partition table...")
  drive.writeSector(25, openupt.rawPartitionTable())
  print("done.")
elseif args[1] == "lspart" then
  local partitions = openupt.partitions()
  if #partitions == 0 then
    print("fsutil: Drive " .. drive.address:sub(1, 6) .. " contains no partitions")
    return
  end
  print("fsutil: Partitions on drive " .. drive.address:sub(1, 6))
  for i=1, #partitions, 1 do
    print("\nPartition " .. tostring(i) .. ":")
    local guid = partitions[i].guid
    local formattedGuid = ""
    for i=1, #guid, 1 do
      formattedGuid = formattedGuid .. string.format("%x", string.byte(guid:sub(i, i))):upper()
    end
    print("GUID:", formattedGuid)
    print("Label:", partitions[i].label)
    print("Start:", partitions[i].start)
    print("End:", partitions[i]["end"])
    print("Size:", partitions[i].size / 512)
  end
elseif args[1] == "delpart" then
  local partitions = openupt.partitions()
  local partn = #partitions
  local part = ""
  if partn == 0 then
    return print("fsutil: Drive " .. drive.address:sub(1, 6) .. " contains no partitions")
  end
  if partn > 1 then
    print("Please select a partition.")
    for i=1, partn, 1 do
      print("Partitions on drive " .. drive.address:sub(1, 6))
      print("Partition " .. tostring(i) .. ":")
      local guid = partitions[i].guid
      local formattedGuid = ""
      for i=1, #guid, 1 do
        formattedGuid = formattedGuid .. string.format("%x", string.byte(guid:sub(i, i))):upper()
      end
      print("GUID:", formattedGuid)
      print("Label:", partitions[i].label)
      print("Size:", partitions[i].size / 512)
    end
    print("Please choose one.")
  else
    part = partitions[1].guid
  end
  local formattedGuid = ""
  for i=1, #part, 1 do
    formattedGuid = formattedGuid .. string.format("%x", string.byte(part:sub(i, i))):upper()
  end
  io.write("Deleting partition with GUID " .. formattedGuid .. "...")
  openupt.delpart(part)
  io.write("done.\nWriting partition table...")
  drive.writeSector(25, openupt.rawPartitionTable())
  print("done.")
elseif args[1] == "bootsector" then
  if not args[2] then
    return print("fsutil: Boot sector file not specified.")
  end
  local file = shell.resolve(args[2])
  if not fs.exists(file) then
    return print("fsutil: File does not exist")
  end
  print("fsutil: Reading file")
  local h = io.open(file)
  local sector = h:readAll():sub(1, 512)
  h:close()
  print("fsutil: Padding data")
  local zero = string.char(0)
  while #sector < 512 do
    sector = sector .. zero
  end
  io.write("fsutil: Writing boot sector...")
  drive.writeSector(1, sector)
  print("done.")
else
  return print("Unrecognized option " .. args[1])
end
