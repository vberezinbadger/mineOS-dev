-- cd: change directory --

local args, options = shell.parse(...)

local users = require("users")

local dir

if args[1] then
  dir = fs.clean(shell.resolve(args[1]))
else
  dir = users.home()
end

local ok, err = shell.setWorkingDirectory(dir)
if not ok then return print("cd: " .. err) end
