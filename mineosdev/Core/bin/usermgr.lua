-- usermgr: Manage users on your system --

local args, options = shell.parse(...)

local verbose = options.v or options.verbose or false

local users = require("users")

local usage = [[User Manager commands:
help:        Display this help.
exit:        Exit User Manager.
list:        List all currently registered users.
add [user]:  Add a user.
del [user]:  Delete a user. If you are not root you will need the user's password.
]]

if options.h or options.help then
  print(usage)
  return true
end

if #args > 0 then
  if args[1] == "add" then
    if args[2] then
      print("Adding user " .. args[2])
      users.adduser(args[2])
    else
      local u = ""
      repeat
        io.write("username: ")
        u = read()
      until u ~= ""
      users.adduser(u)
    end
  elseif args[1] == "del" then
    if args[2] then
      print("Deleting user " .. args[2])
      users.deluser(args[2])
    else
      local u = ""
      repeat
        io.write("username: ")
        u = read()
      until u ~= ""
      users.deluser(u)
    end
  elseif args[1] == "list" then
    for user in table.iter(users.list()) do
      print(user)
    end
  elseif args[1] == "help" then
    print(usage)
  end
  return
end

print("User Manager, version 1.0.")
print("Kolibra Studios 2022. All rights reserved.")
print(" ")
print("Type 'help' for help.")
print(" ")

while true do
  io.write("usermgr> ")
  local input = read()
  if input and input ~= "" then
    input = string.tokenize(" ", input)
    if input[1] == "exit" then
      print("Exiting User Manager.")
      os.exit()
    elseif input[1] == "help" then
      print(usage)
    elseif input[1] == "add" then
      local name = input[2] or ""
      if name == "" or not name then
        repeat
          io.write("Username: ")
          name = read()
        until name ~= ""
      end
      local ok, err = users.adduser(name)
      if not ok then
        error(err)
      end
    elseif input[1] == "list" then
      for user in table.iter(users.list()) do
        print(user)
      end
    elseif input[1] == "del" then
      local name = input[2] or ""
      if name == "" or not name then
        repeat
          io.write("Username: ")
          name = read()
        until name ~= ""
      end
      local ok, err = users.deluser(name)
      if not ok then
        error(err)
      end
    end
  end
end
