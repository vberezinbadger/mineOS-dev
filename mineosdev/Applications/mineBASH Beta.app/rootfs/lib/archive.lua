-- Simple, custom archive format. --

local acv = {}

local DESTFILE = ""

local function getData(line)
  checkArg(1, line, "string")
  local data = {false, nil, nil} -- isDefinition, type, path. All paths are treated as relative.
  if line:sub(1, 9) == "::ACVDATA" then
    data[1] = true
    if line:sub(11, 24) == "type=DIR,path=" then
      data[2] = "directory"
      data[3] = line:sub(25)
    elseif line:sub(11,25) == "type=FILE,path=" then
      data[2] = "file"
      data[3] = line:sub(26)
    end
  end
  return data, line
end

function acv.unpack(file, dest)
  checkArg(1, file, "string")
  checkArg(2, dest, "string")
  fs.makeDirectory(dest)
  local handle, err = io.open(file)
  if not handle then
    return false, err
  end
  local data = handle:readAll()
  handle:close()
  local outhandle
  for line in data:gmatch("[^\n]+") do
    local linedata, text = getData(line)
    if not linedata[1] then
      if outhandle then
        outhandle:write(text .. "\n")
      end
    else
      print("Extracting " .. linedata[3])
      if linedata[2] == "directory" then
        fs.makeDirectory(dest .. "/" .. linedata[3])
      else
        if outhandle then outhandle:close() end
        outhandle = io.open(dest .. "/" .. linedata[3], "w")
      end
    end
  end
end

local archived = {}

local function writeData(dir, out, recurse)
  local recurse = recurse or ""
  local absolutePath = fs.clean(dir .. "/" .. recurse)
  print("Contents of " .. absolutePath)
  local files = fs.list(absolutePath)
  if not files then return end
  for file in table.iter(files) do
    local acvfile = fs.clean(absolutePath .. "/" .. file)
    if acvfile ~= DESTFILE and not archived[acvfile] then -- Prevent recursion and double-archiving
      print("Archiving " .. acvfile)
      archived[acvfile] = true
      if fs.isDirectory(acvfile) then
        out:write("::ACVDATA type=DIR,path=" .. fs.clean(recurse .. "/" .. file) .. "\n")
        writeData(dir, out, recurse .. "/" .. file)
      else
        local h, e = io.open(acvfile)
        if not h then print(e)
        else out:write("::ACVDATA type=FILE,path=" .. fs.clean(recurse .. "/" .. file) .. "\n") out:write(h:readAll() .. "\n") h:close()
        end
      end
    end
  end
end

function acv.pack(dir, dest)
  checkArg(1, dir, "string")
  checkArg(2, dest, "string")
  if not fs.exists(dir) then
    return false, dir .. ": No such file or directory"
  end
  DESTFILE = fs.clean(dest)
  local output, err = io.open(dest, "w")
  writeData(dir, output)
  output:close()
  return true
end

return acv
