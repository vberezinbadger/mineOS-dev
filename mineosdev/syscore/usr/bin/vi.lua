-- vi: vi clone --

-- maybe, finally, actually, a reliable text editor??

local args, options = shell.parse(...)

local event = require("event")
local keyboard = require("base_keyboard")

local wrap = options.w or options.wrap or false

if #args < 1 then
  return print("usage: vi FILE")
end

local path = shell.resolve(args[1])

local fdata = "\n"
if fs.exists(path) then
  local handle = io.open(path)
  fdata = handle:readAll()
  handle:close()
end
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
local w, h = gpu.getResolution()

local cursorX, cursorY = 1, 1

local status = path

local function save()
  local handle = io.open(path, "w")
  for line in table.iter(data) do
    handle:write(line)
  end
  handle:close()
end

local function redraw()
  gpu.setCursor(1,1)
  local ey = 0
  for i=top, (top+h-2 <= #data and top+h-2) or #data, 1 do
    gpu.fill(1, i - top + 1, w, 1, " ")
    print((data[i]:sub(edge, w + edge - 1) == "" and "") or data[i]:sub(edge, w + edge - 1):sub(1, -2))
    ey = ey + 1
  end
  gpu.fill(1, ey + 1, h, w - ey - 1, " ")
  gpu.set(1, h, status .. (" "):rep(w - #status))
  local oldc = gpu.get(cursorX - (edge - 1), cursorY)
  local oldf = gpu.getForeground()
  local oldb = gpu.getBackground()
  gpu.setForeground(oldb)
  gpu.setBackground(oldf)
  gpu.set(cursorX - (edge - 1), cursorY, oldc)
  gpu.setForeground(oldf)
  gpu.setBackground(oldb)
end

local function execCommand(cmd)
  for char in cmd:gmatch(".") do
    if char == "q" then
      gpu.fill(1, 1, w, h, " ")
      gpu.setCursor(1,1)
      os.exit()
    elseif char == "w" then
      save()
    end
  end
end

gpu.fill(1, 1, w, h, " ")

local lineNum = 1

local insert = false

while true do
  if cursorX > #data[lineNum] then
    cursorX = #data[lineNum]
    edge = 1
  end
  redraw()
  local e, _, id, code = event.pull()
  if e == "key_down" then
    if id >= 32 and id <= 127 and insert then
      data[lineNum] = data[lineNum]:sub(0, cursorX - 1) .. string.char(id) .. data[lineNum]:sub(cursorX)
      if cursorX == w and cursorX < #data[lineNum] then
        edge = edge + 1
        cursorX = cursorX + 1
      elseif cursorX < #data[lineNum] then
        cursorX = cursorX + 1
      end
      if (cursorX - edge) >= w then
        edge = (cursorX - w) + 1
      end
    elseif string.char(id) == "i" then
      insert = true
      status = "--INSERT--"
    elseif string.char(id) == ":" then
      status = ""
      local oldx, oldy = cursorX, cursorY
      cursorX, cursorY = edge, h
      redraw()
      gpu.setCursor(1, h)
      io.write(":")
      local editorcommand = read()
      execCommand(editorcommand)
      cursorX, cursorY = oldx, oldy
    elseif id == 8 then -- Backspace
      if insert then
        if cursorX > 1 then
          data[lineNum] = data[lineNum]:sub(0, cursorX - 2) .. data[lineNum]:sub(cursorX, -1)
        elseif cursorX == 1 and lineNum > 1 then
          data[lineNum - 1] = data[lineNum - 1]:sub(1, -2) .. data[lineNum]
          table.remove(data, lineNum)
          if lineNum > 1 then
            lineNum = lineNum - 1
          end
          if cursorY == 1 then
            if top > 1 then
              top = top - 1
            end
          elseif cursorY > 1 then
            cursorY = cursorY - 1
          end
        end
      end
      if cursorX == 1 and edge > 1 then
        edge = edge - 1
      elseif cursorX > 1 then
        cursorX = cursorX - 1
      end
    elseif id == 13 then -- Enter
      if insert then
        table.insert(data, lineNum, "\n")
      end
      if lineNum < #data then
        lineNum = lineNum + 1
      end
      if cursorY == h then
        if top + h - 1 < #data then
          top = top + 1
        end
      elseif cursorY + top < #data then
        cursorY = cursorY + 1
      end
    elseif id == 0 then
      if code == 210 then -- Insert
        insert = (not insert)
        status = (insert and "--INSERT--" or "")
      elseif code == 200 then -- Up arrow
        if lineNum > 1 then
          lineNum = lineNum - 1
          if lineNum < cursorX then
            cursorX = #data[lineNum]
          end
        end
        if cursorY == 1 then
          if top > 1 then
            top = top - 1
          end
        elseif cursorY > 1 then
          cursorY = cursorY - 1
        end
      elseif code == 208 then -- Down arrow
        if lineNum < #data then
          lineNum = lineNum + 1
        end
        if cursorY == h - 1 then
          if top + h - 1 < #data then
            top = top + 1
          end
        elseif cursorY + top  - 1 < #data then
          cursorY = cursorY + 1
        end
      elseif code == 205 then -- Right arrow
        if (cursorX - edge) >= w then
          edge = edge + 1
        elseif cursorX < #data[lineNum] then
          cursorX = cursorX + 1
        end
        if cursorX - edge >= w then
          edge = (cursorX - w) + 1
        end
      elseif code == 203 then -- Left arrow
        if (cursorX - edge) == 1 and edge > 1 then
          edge = edge - 1
        elseif cursorX > 1 then
          cursorX = cursorX - 1
        end
      end
    end
  end
end
