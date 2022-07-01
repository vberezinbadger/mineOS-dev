-- eeprom: EEPROM manager --

local args, options = shell.parse(...)

local cmds = 
[[Commands:
  help:                   Can also be specified as --help from the command line; prints this message.
  flash [file]:           Flash [file] to an EEPROM. If run from the command line, --noprompt can be specified to disable prompts.
  contents:               Print the contents of the currently installed EEPROM.
  data [set|get|clear] [data]:
    sub-operation set:    Set the current EEPROM's data to [data]- maximum data size is 256 bytes.
    sub-operation get:    Print the current EEPROM's stored data.
    sub-operation clear:  Clear the current EEPROM's stored data.]]

if options.help then
  print([[eeprom (c) 2020 Ocawesome101 under the MIT license.
usage: eeprom [command] [opt1] [opt2] ...
If no [command] is specified, will drop to a prompt.
]])
  print(cmds)
  return
end

local noprompt = options.noprompt or false

local event = require("event")

print("Insert the EEPROM you want to work with. Press [enter] when ready.")
repeat
  local e, _, id = event.pull()
until e == "key_down" and id == 13

local eeprom = require("eeprom")
if not eeprom then error("No EEPROM is installed!") end

local function interpret(cmd, a1, a2)
  if cmd == "help" then
    print(cmds)
  elseif cmd == "contents" then
    print("Contents of EEPROM", eeprom.address)
    print(eeprom.get())
  elseif cmd == "flash" then
    local a1 = a1 or ""
    if a1 == "" and not noprompt then
      repeat
        io.write("file: ")
        a1 = io.read()
      until a1 ~= ""
    end
    a1 = shell.resolve(a1)
    if not fs.exists(a1) then
      print("File " .. a1 .. " does not exist")
      return false
    end
    if fs.size(a1) > eeprom.getSize() then
      print("File " .. a1 .. " is too large")
      return false
    end
    local handle, err = io.open(a1)
    if not handle then
      print(err)
      return false
    end
    local data = handle:readAll()
    handle:close()
    if not noprompt then
      io.write("Really flash " .. a1 .. " to the EEPROM? [y/N]: ")
      repeat
        local e,_,id = event.pull()
        if e == "key_down" and string.char(id):lower() == "n" then
          print("Canceling.")
          os.exit()
        end
      until e == "key_down" and string.char(id):lower() == "y"
    end
    print("Flashing EEPROM. Do NOT restart your computer or remove the EEPROM during this process!")
    eeprom.set(data)
    print("Done. You may restart your computer or remove the EEPROM now.")
  elseif cmd == "data" then
    if a1 == "get" then
      print("Data of EEPROM", eeprom.address)
      print(eeprom.getData())
    elseif a1 == "set" then
      local a2 = a2 or ""
      if a2 == "" then
        repeat
          io.write("data: ")
          a2 = io.read()
        until a2 ~= ""
      end
      print("Setting data to " .. a2)
      eeprom.setData(data)
      print("Done.")
    elseif a1 == "clear" then
      print("Clearing data")
      eeprom.setData("")
      print("Done.")
    else
      print("data: " .. a1 .. ": Unrecognized operation")
      return false
    end
  else
    print(cmd .. ": Unrecognized operation")
    return false
  end
  return true
end

if #args < 1 then
  print("eeprom (c) 2020 Ocawesome101 under the MIT License.")
  print("Type 'help' for help.")
  while not exit do
  end
else
  interpret(table.unpack(args))
end
