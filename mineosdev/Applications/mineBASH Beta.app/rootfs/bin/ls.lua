-- ls: list the contents of a directory --

local args, options = shell.parse(...)

local color = (options.nocolor and false) or true
local hidden = options.a or options.all or false
local fileColor = 0xFFFFFF
local scriptColor = color and 0x33FF33 or 0xFFFFFF
local dirColor = color and 0x00BDFF or 0xFFFFFF

local function tabbedPrint(d, tbl)
  checkArg(1, tbl, "table")
  local w,h = gpu.getResolution()
  local maxlen = 1
  for i=1, #tbl, 1 do
    if #tbl[i] > maxlen then
      maxlen = #tbl[i]
    end
  end
  maxlen = maxlen + 2 -- there should be space between this stuff
  local x = 1
  for i=1, #tbl, 1 do
    local s = tbl[i]
    while #s < maxlen do
      s = s .. " "
    end
    if fs.isDirectory(d .. "/" .. tbl[i]) then
      gpu.setForeground(dirColor)
    elseif tbl[i]:sub(-4) == ".lua" then
      gpu.setForeground(scriptColor)
    else
      gpu.setForeground(fileColor)
    end
    if s:sub(1,1) ~= "." or hidden then
      io.write(s)
    end
  end
  if #tbl > 0 then
    io.write("\n")
  end
end

if #args > 0 then
  for i=1, #args, 1 do
    local dir = shell.resolve(args[i])
    if not fs.exists(dir) then print("ls: " .. dir .. ": No such file or directory")
    else
      gpu.setForeground(0xFFFFFF)
      print(dir .. ":")
      local files = fs.list(dir)

      table.sort(files)
      tabbedPrint(dir, files)
    end
  end
else
  local dir = shell.getWorkingDirectory()
  local files = fs.list(dir) or {}
  
  table.sort(files)
  tabbedPrint(dir, files)
end
