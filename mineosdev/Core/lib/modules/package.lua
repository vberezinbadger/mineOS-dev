-- Module system. Not the most memory-friendly, but it works. And, it's (mostly) standard-Lua-compliant! --

_G.package = {}

package.path = "/lib/?.lua;/lib/?/init.lua;/usr/lib/?.lua;/usr/lib/?/init.lua;/usr/lib/compat/?.lua;/usr/lib/compat/?/init.lua"

package.loaded = {
  ["_G"] = _G,
  ["string"] = string,
  ["table"] = table,
  ["math"] = math,
  ["bit32"] = bit32,
  ["coroutine"] = coroutine,
  ["component"] = component,
  ["computer"] = computer,
  ["unicode"] = unicode,
  ["event"] = event,
  ["devfs"] = devfs
}

_G.component, _G.computer, _G.unicode, _G.event, _G.devfs = nil, nil, nil, nil, nil

local function genLibError(n)
  local err = "module '" .. n .. "' not found:\n  no field package.loaded['" .. n .. "']"
  for path in string.tokenize(";", package.path) do
    err = err .. "\n\tno file '" .. path:gsub("%?", n) .. "'"
  end
  return err
end

-- TODO: Do something with path, sep, rep
function package.searchpath(name, path, sep, rep) -- Search the module path for a package
  checkArg(1, name, "string")
  checkArg(2, path, "string", "nil")
  checkArg(3, sep, "string", "nil")
  checkArg(4, rep, "string", "nil")
  local paths = string.tokenize(";", package.path)
  for path in paths do
    path = fs.clean(path)
    module = path:gsub("%?", name)
    if fs.exists(module) then
      return module
    end
  end
  return false, genLibError(name)
end

function _G.dofile(file)
  checkArg(1, file, "string")
  local ok, err = loadfile(file)
  if not ok then
    return false, err
  end
  local s, r = pcall(ok)
  if not s then
    return false, r
  end
  return r
end

function _G.require(library)
  checkArg(1, library, "string")
  if library:sub(1, 1) == "/" then
    return dofile(library)
  elseif package.loaded[library] then
    return package.loaded[library]
  else
    local path, err = package.searchpath(library)
    if not path then
      return false, err
    end
    local a, r = dofile(path)
    if a and type(a) == "table" then package.loaded[library] = a end
    return a, r
  end
end

local component = require("component")

for addr, ctype in component.list() do
  if ctype ~= "filesystem" and ctype ~= "gpu" and ctype ~= "screen" and ctype ~= "keyboard" and ctype ~= "sandbox" and not package.loaded[ctype] then
    kernel.log("components: creating proxy: type " .. ctype .. ", address " .. addr)
    package.loaded[ctype] = component.proxy(addr)
  end
end
