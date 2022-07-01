-- cat: print the contents of a file --

local args, options = shell.parse(...)

if #args < 1 then
  return print("Usage: cat FILE")
end

local handle, err = io.open(shell.resolve(args[1]))
if not handle then return print("cat: " .. err) end

local data = handle:readAll()
handle:close()

print(data)
