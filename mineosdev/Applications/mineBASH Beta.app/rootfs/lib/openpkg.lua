-- Package management library. Having package management structured this way allows for custom frontends, similar to Arch's ALPM. --
-- Packages are stored using custom archives. --
-- This library does not, I repeat, does NOT natively support any kind of package lists. You will need to program lists into your frontend.

local pkg = {}

local acv = require("archive")
local cfg = require("config")

local packages = cfg.load("/usr/share/openpkg/installed.cfg") or {}

function pkg.installPackage(file)
  checkArg(1, file, "string")
  if not fs.exists(file) then
    return false, file .. ": No such file or directory"
  end
  print("openpkg: Parsing package configuration")
  if file:sub(-4) == ".acv" then
    acv.unpack(file, fs.clean("/tmp/" .. fs.name(file:sub(1, -5))))
  else
    return false, "File " .. file .. " does not have the .acv extension"
  end
  local path = fs.clean("/tmp/" .. fs.name(file:sub(1, -5)))
--  print(path .. "/package.cfg")
  if not fs.exists(path .. "/package.cfg") then
    return false, "Package contains no package.cfg"
  end
  local pkgConf, err = cfg.load(path .. "/package.cfg") -- Why doesn't this work?!
  if not pkgConf and err then
    return false, err
  end
  print(table.serialize(pkgConf))
  if not (pkgConf.name and pkgConf.files and pkgConf.arch) then
    return false, "Invalid package.cfg: missing name, files, or arch"
  end
  local name = pkgConf.name
  local files = pkgConf.files
  local arch = pkgConf.arch
  if arch ~= "Lua 5.3" and arch ~= "Lua 5.2" and arch ~= "all" then
    return false, "Invalid package architecture " .. arch
  end
  if arch ~= _VERSION and arch ~= "all" then
    return false, "Package architecture " .. arch .. " does not match CPU architecture"
  end
  print("openpkg: Searching package database")
  if packages[name] then
    print("openpkg: Package is already installed. Reinstalling.")
  end
  print("openpkg: Installing package " .. name)
  packages[name] = {files = table.new()}
  for k,v in pairs(files) do
    local src = fs.clean(path .. "/" .. k)
    local dest = fs.clean(v)
    print(src .. " -> " .. dest)
    if fs.exists(dest) then
      write("WARNING: File " .. v .. " already exists! Overwrite? [y/n]: ")
      local i
      repeat
        i = read()
      until i:lower() == "y" or i:lower() == "n"
      if i:lower() == "n" then
        print("Skipping. Note that some programs may not function correctly.")
      else
        print("Overwriting. Note that some programs may not function correctly.")
        packages[name].files:insert(dest)
        local inhandle, err = io.open(src)
        if not inhandle then
          print("WARNING: " .. err)
        else
          local outhandle = io.open(dest, "w")
          outhandle:write(inhandle:readAll())
          inhandle:close()
          outhandle:close()
        end
      end
    else
      packages[name].files:insert(dest)
      local inhandle, err = io.open(src)
      if not inhandle then
        print("WARNING: " .. err)
      else
        local outhandle = io.open(dest, "w")
        outhandle:write(inhandle:readAll())
        inhandle:close()
        outhandle:close()
      end
    end
  end
  print("openpkg: Saving package configuration")
  config.save(packages, "/usr/share/openpkg/installed.cfg")
end

function pkg.removePackage(name)
  checkArg(1, name, "string")
  print("openpkg: Searching package database")
  if not packages[name] then
    return print("openpkg: Package not installed.")
  end
  local pkgdata = packages[name]
  local files = pkgdata.files
  for i=1, #files, 1 do
    print("openpkg: Removing file " .. files[i])
    fs.remove(files[i])
  end
  print("openpkg: Deleting package entry")
  packages[name] = nil
  print("openpkg: Saving package configuration")
  config.save(packages, "/usr/share/openpkg/installed.cfg")
end

return pkg
