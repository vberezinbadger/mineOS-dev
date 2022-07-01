-- openpm: package management utility inspired by Pacman --

local args = {...}

local pkg,e  = require("openpkg") -- This does some of the heavy lifting
local config = require("config")
local netutils = require("netutils")
if not pkg then return print(e) end

if #args <= 1 and args[1] ~= "update" then
  if args[1] == "help" then
    print("usage: openpm <operation> [...]")
    print("operations:")
    print("  openpm help")
    print("  openpm files           <package(s)>")
--    print("  openpm query    <package(s)>")
    print("  openpm install         [package(s)]")
    print("  openpm remove          <package(s)>")
    print("  openpm install-local   <file(s)>")
    print("  openpm update")
  else
    print("error: no operation specified (use 'openpm help' for help)")
  end
  return
end

local packages = config.load("/var/cache/openpm/packages.cfg")

if args[1] == "install" then
  local toInstall = {table.unpack(args, 2, #args)}
  for package in table.iter(toInstall) do
    print("openpm: Searching package list")
    if packages[package] then
      print("openpm: Found package")
      print("openpm: Downloading package archive from " .. packages[package].url)
      netutils.download(packages[package].url, "/var/cache/openpm/packages/" .. package .. ".acv")
      local ok, err = pkg.installPackage("/var/cache/openpm/packages/" .. package .. ".acv")
      if not ok and err then
        print("E: " .. err)
      end
    end
  end
elseif args[1] == "install-local" then
  local file = args[2]
  local path = fs.clean(shell.resolve(file))
  print("openpm: Installing local package " .. path)
  local ok, err = pkg.installPackage(path)
  if not ok and err then
    print("E: " .. err)
  end
elseif args[1] == "update" then
  print("openpm: Reading repolist")
  local repos = config.load("/etc/openpm/repos.cfg")
  local i = 1
  fs.makeDirectory("/tmp/repos")
  for repo in table.iter(repos) do
    print("openpm: Downloading packages.cfg from " .. repo .. "/packages.cfg")
    netutils.download(repo .. "/packages.cfg", "/tmp/repos/" .. tostring(i))
  end
  print("openpm: Creating new package list")
  local newpackages = {}
  for list in table.iter(fs.list("/tmp/repos/")) do
    local tmp = config.load("/tmp/repos/" .. list)
    for k,v in pairs(tmp) do
      newpackages[k] = v
    end
  end
  config.save(newpackages, "/var/cache/openpm/packages.cfg")
elseif args[1] == "remove" then

elseif args[1] then
  return print(args[1] .. ": Invalid operation")
end
