-- less: simple `less` clone --

local args, options = shell.parse(...)

local event = require("event")

local wrap = options.w or options.wrap or false

if #args < 1 then
  return print("usage: less FILE")
end

local path = shell.resolve(args[1])

if not fs.exists(path) then
  return print("less: " .. args[1] .. ": file not found")
end

local handle = io.open(path)
local fdata = handle:readAll()
handle:close()
local data = {}
local line = ""
for char in fdata:gmatch(".") do
  line = line .. char
  if char == "\n" then
    data[#data + 1] = line
    line = ""
  end
end
if line ~= "" then
  data[#data + 1] = line
end

local top, edge = 1, 1
local w,h = gpu.getResolution()

local function redraw()
  gpu.setCursor(1,1)
  for i=top, (top+h-2 <= #data and top+h-2) or #data, 1 do
    gpu.fill(1, i - top + 1, w, 1, " ")
    local printed = print((data[i]:sub(edge, w + edge - 1) == "" and "") or data[i]:sub(edge, w + edge - 1):sub(1, -2))
  end
  gpu.set(1, h, ":")
end

gpu.fill(1, 1, w, h, " ")

while true do
  redraw()
  coroutine.yield()
  local e, _, id, code = event.pull()
  if e == "key_down" then
    if id >= 32 and id <= 127 then
      if string.char(id):lower() == "q" then
        break
      end
    elseif id == 0 then
      if code == 200 then -- Up arrow
        if top > 1 then
          top = top - 1
        end
      elseif code == 208 then -- Down arrow
        if top + h < #data then
          top = top + 1
        end
      elseif code == 205 then -- Right arrow
        edge = edge + 5
      elseif code == 203 then -- Left arrow
        if edge > 5 then
          edge = edge - 5
        else
          edge = 1
        end
      end
    end
  end
end

gpu.fill(1, 1, w, h, " ")
gpu.setCursor(1,1)
