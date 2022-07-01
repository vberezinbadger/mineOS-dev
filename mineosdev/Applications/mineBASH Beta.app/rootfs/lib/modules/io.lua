-- A proper io library. How quaint! --

_G.io = {}

local buffer = require("buffer")

_G.print, _G.write = nil, nil

io.stdin = buffer.new("r", "-")
io.stdout = buffer.new("w", "-")

io.output = function()return io.stdout end
io.input = function()return io.stdin end

function io.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  return buffer.new(mode, file)
end

function io.read()
  return io.input():read()
end

function io.write(data)
  return io.output():write(data)
end

function io.close()
  io.output():flush()
  io.output():close()
  io.stdout = buffer.new(nil, "w")
end

function io.flush()
  return io.output():flush()
end

_G.print = function(...)
  local p = {...}
  for i=1, #p, 1 do
    io.write(tostring(p[i]))
    if i < #p then
      io.write(" ")
    end
  end
  io.write("\n")
end
