-- mkdir: Make directories --

local args, options = shell.parse(...)

local verbose = options.v or options.verbose or false

if #args < 1 then
  return print("mkdir: missing operand")
end

for dir in table.iter(args) do
  local dir = shell.resolve(dir)
  if verbose then print("Creating " .. dir) end
  fs.makeDirectory(dir)
end
