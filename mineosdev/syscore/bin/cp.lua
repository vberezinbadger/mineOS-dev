-- cp: copy files --

local args, options = shell.parse(...)

local verbose = options.v or options.verbose or false
local recurse = options.r or options.recurse

if #args < 2 then
  return print("cp: Missing file operand")
end

local s, d = shell.resolve(args[1]), shell.resolve(args[2])

if not fs.exists(s) then
  error(s .. ": file does not exist")
end

-- TODO: add recursion
if fs.isDirectory(s) then
  error("Cannot copy a directory")
end

local ok, err = fs.copy(s, d)
if not ok then
  error(err)
end
