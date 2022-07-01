-- Basic module loading system -- 

_G.module = {}

module.path = "/lib;/lib/require;/usr/lib"

module.loaded = {
  ["_G"] = _G,
  ["math"] = math,
  ["string"] = string,
  ["table"] = table,
  ["colors"] = colors,
  ["computer"] = table.copy(computer),
  ["component"] = table.copy(component),
  ["unicode"] = table.copy(unicode),
  ["module"] = module,
  ["term"] = term,
  ["event"] = event
}

-- unclutterification
_G.component, _G.computer, _G.unicode = nil, nil, nil

local ok, err = loadfile("/lib/tokenize.lua")
if not ok then
  printError(err)
  return false, err
end
local tokenize = ok()

function module.search(lib)
  local paths = tokenize(";", module.path)
  for i=1, #paths, 1 do
    if fs.exists(paths[i] .. "/" .. lib .. ".lua") then
      return paths[i] .. "/" .. lib .. ".lua"
    elseif fs.exists(paths[i] .. "/" .. lib .. "/" .. lib .. ".lua") then
      return paths[i] .. "/" .. lib .. "/" .. lib .. ".lua"
    elseif fs.exists(paths[i] .. "/" .. lib .. "/init.lua") then
      return paths[i] .. "/" .. lib .. "/init.lua"
    end
  end
  return false, "Module not found"
end

function dofile(file, ...)
  local ok, err = loadfile(file)
  if not ok then
    printError(err)
    return false, err
  end
  return ok(...)
end

function require(modulename)
  if module.loaded[modulename] then
    return module.loaded[modulename]
  else
    local path, err = module.search(modulename)
    if not path then
      return false, err
    else
      local mod, err = dofile(path)
      if not mod then
        return false, err
      else
        module.loaded[modulename] = mod
        return module.loaded[modulename]
      end
    end
  end
end
