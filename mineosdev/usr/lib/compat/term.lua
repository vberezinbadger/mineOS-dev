-- Wrapper around the already-wrapped GPU component, primarily for OpenOS compatibility. --

local event = require("event")
local component = require("component")

local term = {}

function term.isAvailable()
  return true
end

function term.getViewport()
  local w, h = gpu.getResolution()
  local xo, yo, rx, ry = 1, 1, 1, 1
  return w, h, xo, yo, rx, ry
end

function term.gpu()
  return _G.gpu
end

function term.pull(f, t)
  return event.pull(f, t)
end

function term.getCursor()
  return gpu.getCursor()
end

function term.setCursor(x, y)
  return gpu.setCursor(x, y)
end

function term.getCursorBlink()
  return true
end

function term.setCursorBlink() -- stub
  return
end

function term.clear()
  local w,h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
  gpu.setCursor(1, 1)
end

function term.clearLine()
  local x, y = gpu.getCursor()
  local w, h = gpu.getResolution()
  gpu.fill(1, y, w, 1, " ")
  gpu.setCursor(1, y)
end

function term.read(hist)
  return read(hist)
end

function term.write(str)
  return io.stdout:write(str)
end

function term.screen()
  return gpu.getScreen()
end

function term.getGlobalArea()
  local x, y = 1, 1
  local w, h = gpu.getResolution()
  return x, y, w, h
end

function term.keyboard()
  local kbs = component.invoke(gpu.getScreen(), "getKeyboards")
  if kbs[1] then 
    return kbs[1]
  else
    return ""
  end
end

return term
