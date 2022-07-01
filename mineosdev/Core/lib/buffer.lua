-- Buffering --

local buffer = {}

local computer = require("computer")

local mt = {__index = buffer}

local write = write or io.write

function buffer.new(mode, file)
  checkArg(1, mode, "string", "nil")
  checkArg(2, file, "string")
  local file = file or "-"
  local rtn = {
    tty = false,
    mode = {},
    rbuf = "",
    wbuf = "",
    bufsize = math.floor(computer.freeMemory() / 8),
    stream = {}
  }
  local mode = mode or "r"
  for c in mode:gmatch(".") do
    rtn.mode[c] = true
  end
  if file == "-" then -- stdio
    rtn.tty = true
    if rtn.mode.r then
      rtn.stream.read = read
    end
    if rtn.mode.w then
      rtn.stream.write = write
    end
    rtn.stream.close = function() rtn.stream = {} end
  else
    local handle, err = fs.open(file, mode)
    if not handle then
      return false, err
    end
    rtn.stream = handle
  end
  return setmetatable(rtn, mt)
end

function buffer:read(amount, replace, history) -- little bit of a hack to make things work properly
  if amount == "*a" then
    amount = 0xFFFF
  end
  checkArg(1, amount, "number")
  if not self.mode.r then
    return false, "Read mode is not enabled on this stream"
  end
  if self.tty then
    return self.stream.read(replace, history)
  end
  if #self.rbuf >= amount then
    local tmp = self.rbuf:sub(0 - amount)
    self.rbuf = self.rbuf:sub(1, 0 - amount - 1)
    return tmp
  else
    local tmp = self.rbuf .. self.stream.read(amount - #self.rbuf)
    self.rbuf = self.stream.read(self.bufsize)
    return tmp
  end
end

function buffer:readAll()
  if not self.mode.r then
    return false, "Read mode is not enabled on this stream"
  end
  if self.tty then
    return self.stream.read()
  end
  local d = ""
  repeat
    local b = self.stream.read(0xFFFF)
    d = d .. (b or "")
  until not b
  return d
end

function buffer:write(text)
  checkArg(1, text, "string")
  if not self.mode.w then
    return false, "Write mode is not enabled on this stream"
  end
  if self.tty then
    self.stream.write(text)
    return
  end
  if self.bufsize - #self.wbuf >= #text then
    self.wbuf = self.wbuf .. text
  elseif #text <= self.bufsize then
    local diff = self.bufsize - #self.wbuf
    diff = #text - diff
    self.stream.write(self.wbuf:sub(1, diff))
    self.wbuf = self.wbuf:sub(1, diff + 1) .. text
  else
    local tmp = self.wbuf .. text:sub(1, 0 - (#text - self.bufsize))
    self.wbuf = text:sub(1 - (#text - self.bufsize))
    self.stream.write(tmp)
  end
end

function buffer:flush()
  local tmp = self.wbuf
  self.wbuf = ""
  self.stream.write(tmp)
end

function buffer:lines()
  if not self.mode.r then
    return false, "Read mode is not enabled on this stream"
  end
  local start = 1
  return function()
    if #self.rbuf < self.bufsize then
      self.rbuf = self.rbuf .. (self.stream.read(self.bufsize - #self.rbuf) or "")
    end
    local i = self.rbuf:find("\n", start)
    if not i then
      return nil
    end
    local tmp = self.rbuf:sub(start, i)
    start = i + 1
    return tmp
  end
end

function buffer:close()
  if self.mode.w then self:flush() end
  return self.stream.close()
end

return buffer
