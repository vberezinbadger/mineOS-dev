-- led: line editor --

local args, options = shell.parse(...)

if #args < 2 or options.h or options.help then
  return print("usage: led FILE LINE")
end

local file = shell.resolve(args[1])
if not fs.exists(file) then
  return print("led: " .. args[1] .. ": No such file or directory")
end

local h = io.open(file)

local lines = string.tokenize("\n", h:readAll())

h:close()

local ln = tonumber(args[2])
if not ln then
  return print("led: '" .. args[2] .. "' is not a number")
end

if not lines[ln] then
  return print("led: line " .. args[2] .. " is not present in file " .. args[1])
end

local out, num = read(nil, lines, lines[ln], ln)

lines[num] = out

local fdata = table.concat(lines, "\n")
local h = io.open(file, "w")
h:write(fdata)
h:close()
