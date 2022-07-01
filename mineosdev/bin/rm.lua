-- rm: delete a file or directory --

local args, options = shell.parse(...)

local force = options.f or options.force or false
local ask = options.i or false
local verbose = options.v or options.verbose or false

local event = require("event")

if #args < 1 then
  return print("usage: rm FILE1 FILE2 ...")
end

for i=1, #args, 1 do
  local path = fs.clean(shell.resolve(args[i]))
  if not fs.exists(path) then
    print("rm: " .. path .. ": No such file or directory")
  else
    if ask then
      io.write("rm: Remove " .. path .. "? [y/n] ")
      local k = ""
      repeat
        local e,_,id=event.pull()
        if id then
          k = string.char(id):lower()
        end
      until e == "key_down" and k == "y" or k == "n"
      if k == "y" then
        print("y\nRemoving " .. path)
        fs.remove(path)
      else
        print("n\nSkipping " .. path)
      end
    else
      if verbose then
        print("Removing " .. path)
      end
      fs.remove(path)
    end
  end
end
