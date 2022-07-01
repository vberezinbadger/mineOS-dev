 -- mineCORE 3.0 Reborn --

local flags = ... or {}

local bootAddress = computer.getBootAddress()
local startTime = computer.uptime()

local filesystems = {}
local bootfs = component.proxy(((pcall(component.type, flags.bootAddress)) and flags.bootAddress) or bootAddress) -- You can specify a custom boot-address, this should check if it's valid
local init = flags.init or "/sbin/init.lua"

-- component proxies
for addr, ctype in component.list() do
  if ctype == "gpu" then
    _G.gpu = _G.gpu or component.proxy(addr)
  elseif ctype == "filesystem" then
    filesystems[addr] = component.proxy(addr)
  elseif ctype == "screen" then
    if gpu then
      gpu.bind(addr)
    end
  end
end

gpu.setResolution(gpu.maxResolution())
gpu.setForeground(0xFFFFFF)
gpu.setBackground(0x000000)

local x, y = 1, 1
local w, h = gpu.getResolution()

gpu.fill(1, 1, w, h, " ")

function gpu.getCursor()
  return x, y
end

function gpu.setCursor(X,  Y)
  checkArg(1, X, "number")
  checkArg(2, Y, "number")
  x, y = X, Y
end

function gpu.scroll(amount)
  checkArg(1, amount, "number")
  gpu.copy(1, 1, w, h, 0, 0 - amount)
  gpu.fill(1, h, w, amount, " ")
end

function write(str)
  checkArg(1, str, "string")
  local written = 0
  local function newline()
    x = 1
    if y + 1 <= h then
      y = y + 1
    else
      gpu.scroll(1)
      y = h
    end
    written = written + 1
  end
  str = str:gsub("\t", "    ")
  while #str > 0 do
    local space = str:match("^[ \t]+")
    if space then
      gpu.set(x, y, space)
      x = x + #space
      str = str:sub(#space + 1)
    end

    local newLine = str:match("^\n")
    if newLine then
      newline()
      str = str:sub(2)
    end

    local word = str:match("^[^ \t\n]+")
    if word then
      str = str:sub(#word + 1)
      if #word > w then
        while #str > 0 do
          if x > w then
            newline()
          end
          gpu.set(x, y, text)
          x = x + #text
          text = text:sub((w - x) + 2)
        end
      else
        if x + #word > w then
          newline()
        end
        gpu.set(x, y, word)
        x = x + #word
      end
    end
  end
  return written
end

function print(...)
  local args = {...}
  local printed = 0
  for i=1, #args, 1 do
    local written = write(tostring(args[i]))
    if i < #args then
      write(" ")
    end
    printed = printed + written
  end
  write("\n")
  return printed
end

local uptime = computer.uptime
local function time() -- Properly format the computer's uptime so we can print it nicely
  local r = tostring(uptime()):sub(1,7)
  local c,_ = r:find("%.")
  local c = c or 4
  if c < 4 then
    r = string.rep("0",4-c) .. r
  elseif c > 4 then
    r = r .. string.rep("0",c-4)
  end
  while #r < 7 do
    r = r .. "0"
  end
  return r
end

_G.kernel = {}

kernel._VERSION = "mineCORE 3.0"

pcall(bootfs.rename("/boot/log", "/boot/log.old"))

local kernelLog, err = bootfs.open("/boot/log", "w")
local verbose = flags.verbose

function kernel.log(msg)
  local m = "[" .. time() .. "] " .. msg
  if not flags.disableLogging then bootfs.write(kernelLog, m .. "\n") end
  if verbose then
    print(m)
  end
end

function kernel.setlogs(boolean)
  checkArg(1, boolean, "boolean")
  verbose = boolean
end

kernel.log("[INIT] >> " .. kernel._VERSION .. " booting on " .. _VERSION)

kernel.log("[INIT] >> Total memory: " .. tostring(math.floor(computer.totalMemory() / 1024)) .. "K")
kernel.log("[INIT] >> Free memory: " .. tostring(math.floor(computer.freeMemory() / 1024)) .. "K")

local native_shutdown = computer.shutdown
computer.shutdown = function(b) -- make sure the log file gets properly closed
  kernel.log("[BOOT_FAULURE] >> Shutting down")
  bootfs.close(kernelLog)
  native_shutdown(b)
end

local native_error = error

local pullSignal = computer.pullSignal
local shutdown = computer.shutdown
function _G.error(err, level)
  if level == -1 or level == "__KPANIC__" then
    kernel.setlogs(true) -- The user should see this
    kernel.log(("="):rep(25))
    kernel.log("PANIC: " .. err)
    local traceback = debug.traceback(nil, 2)
    for line in traceback:gmatch("[^\n]+") do
      kernel.log(line)
    end
    kernel.log("Press [S] key to shut down.")
    kernel.log(("="):rep(25))
    while true do
      local e, _, id = pullSignal()
      if e == "key_down" and string.char(id):lower() == "s" then
        shutdown()
      end
    end
  else
    return native_error(err, level or 2)
  end
end

kernel.log("[INIT] >> Initializing filesystems")

bootfs.remove("/mnt")

_G.fs = {}

local mounts = {
  {
    path = "/",
    proxy = bootfs
  }
}

kernel.log("[INIT] >> Stage 1: helpers")
local function cleanPath(p)
  checkArg(1, p, "string")
  local path = ""
  for segment in p:gmatch("[^%/]+") do
    path = path .. "/" .. (segment or "")
  end
  if path == "" then
    path = "/"
  end
  return path
end

local function resolve(path) -- Resolve a path to a filesystem proxy
  checkArg(1, path, "string")
  local proxy
  local path = cleanPath(path)
  for i=1, #mounts, 1 do
    if mounts[i] and mounts[i].path then
      local pathSeg = cleanPath(path:sub(1, #mounts[i].path))
--      kernel.log(pathSeg .. " =? " .. mounts[i].path)
      if pathSeg == mounts[i].path then
        path = cleanPath(path:sub(#mounts[i].path + 1))
        proxy = mounts[i].proxy
      end
    end
  end
  if proxy then
     return cleanPath(path), proxy
  end
end

kernel.__component = component

kernel.log("[INIT] >> Stage 2: mounting, unmounting")
function fs.mount(addr, path)
  checkArg(1, addr, "string")
  checkArg(2, path, "string", "nil")
  local label = kernel.__component.invoke(addr, "getLabel")
  label = (label ~= "" and label) or nil
  local path = path or "/mnt/" .. (label or addr:sub(1, 6))
  path = cleanPath(path)
  local p, pr = resolve(path)
  for _, data in pairs(mounts) do
    if data.path == path then
      if data.proxy.address == addr then
        return true, "[INIT] >> Filesystem already mounted"
      else
        return false, "[INIT] >> Cannot override existing mounts"
      end
    end
  end
  if kernel.__component.type(addr) == "filesystem" then
    if path == "/mnt/devfs" then
      return
    end
    kernel.log("Mounting " .. addr .. " on " .. path)
    if fs.makeDirectory then
      fs.makeDirectory(path)
    else
      bootfs.makeDirectory(path)
    end
    mounts[#mounts + 1] = {path = path, proxy = kernel.__component.proxy(addr)}
    return true
  end
  kernel.log("[INIT] >> Failed mounting " .. addr .. " on " .. path)
  return false, "[INIT] >> Unable to mount"
end

function fs.unmount(path)
  checkArg(1, path, "string")
  for k, v in pairs(mounts) do
    if v.path == path then
      kernel.log("[INIT] >> Unmounting filesystem " .. path)
      mounts[k] = nil
      fs.remove(v.path)
      return true
    elseif v.proxy.address == path then
      kernel.log("[INIT] >> Unmounting filesystem " .. v.proxy.address)
      mounts[k] = nil
      fs.remove(v.path)
    end
  end
  return false, "[INIT] >> No such mount"
end

function fs.mounts()
  local rtn = {}
  for k,v in pairs(mounts) do
    rtn[k] = {path = v.path, address = v.proxy.address, label = v.proxy.getLabel()}
  end
  return rtn
end

kernel.log("[INIT] >> Stage 3: standard FS API")
function fs.exists(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(cleanPath(path))
  if not proxy.exists(path) then
    return false
  else
    return true
  end
end

function fs.open(file, mode)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  if not fs.exists(file) and mode ~= "w"  then
    return false, "[INIT] >> No such file or directory"
  end
  local mode = mode or "r"
  if mode ~= "r" and mode ~= "rw" and mode ~= "w" then
    return false, "[INIT] >> Unsupported mode"
  end
  kernel.log("[INIT] >> Opening file " .. file .. " with mode " .. mode)
  local path, proxy = resolve(file)
  local h, err = proxy.open(path, mode)
  if not h then
    return false, err
  end
  local handle = {}
  if mode == "r" or mode == "rw" or not mode then
    handle.read = function(n)
      return proxy.read(h, n)
    end
  end
  if mode == "w" or mode == "rw" then
    handle.write = function(d)
      return proxy.write(h, d)
    end
  end
  handle.close = function()
    proxy.close(h)
  end
  handle.handle = function()
    return h
  end
  return handle
end

fs.read = bootfs.read
fs.write = bootfs.write
fs.close = bootfs.close

function fs.list(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.list(path)
end

function fs.remove(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.remove(path)
end

function fs.spaceUsed(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceUsed()
end

function fs.makeDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.makeDirectory(path)
end

function fs.isReadOnly(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.isReadOnly()
end

function fs.spaceTotal(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.spaceTotal()
end

function fs.isDirectory(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

--  kernel.log(path .. " " .. proxy.type .. " " .. proxy.address .. " " .. type(proxy.isDirectory))
  return proxy.isDirectory(path)
end

function fs.copy(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")
  local spath, sproxy = resolve(source)
  local dpath, dproxy = resolve(dest)

  local s, err = sproxy.open(spath, "r")
  if not s then
    return false, err
  end
  local d, err = dproxy.open(dpath, "w")
  if not d then
    sproxy.close(s)
    return false, err
  end
  repeat
    local data = sproxy.read(s, 0xFFFF)
    dproxy.write(d, (data or ""))
  until not data
  sproxy.close(s)
  dproxy.close(d)
  return true
end

function fs.rename(source, dest)
  checkArg(1, source, "string")
  checkArg(2, dest, "string")

  local ok, err = fs.copy(source, dest)
  if ok then
    fs.remove(source)
  else
    return false, err
  end
end

function fs.canonicalPath(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)
  for i=1, #segments, 1 do
    if segments[i] == ".." then
      segments[i] = ""
      table.remove(segments, i - 1)
    end
  end
  return cleanPath(table.concat(segments, "/"))
end

function fs.path(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)
  
  return cleanPath(table.concat({table.unpack(segments, 1, #segments - 1)}, "/"))
end

function fs.name(path)
  checkArg(1, path, "string")
  local segments = string.tokenize("/", path)

  return segments[#segments]
end

function fs.get(path)
  checkArg(1, path, "string")
  if not fs.exists(path) then
    return false, "[INIT] >> Path does not exist"
  end
  local path, proxy = resolve(path)

  return proxy
end

function fs.lastModified(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.lastModified(path)
end

function fs.getLabel(path)
  checkArg(1, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.getLabel()
end

function fs.setLabel(label, path)
  checkArg(1, label, "string")
  checkArg(2, path, "string", "nil")
  local path, proxy = resolve(path or "/")

  return proxy.setLabel(label)
end

function fs.size(path)
  checkArg(1, path, "string")
  local path, proxy = resolve(path)

  return proxy.size(path)
end

for addr, _ in component.list("filesystem") do
  if addr ~= bootfs.address then
    if component.invoke(addr, "getLabel") == "tmpfs" then
      fs.mount(addr, "/tmp")
    else
      fs.mount(addr)
    end
  end
end

kernel.log("[INIT] >> Reading /etc/fstab")

-- /etc/fstab specifies filesystems to mount in locations other than /mnt, if any. Note that this is fileystem-specific and as such noin other news, I've t included by default.

local fstab = {}

local handle, err = fs.open("/etc/fstab", "r")
if not handle then
  kernel.log("[INIT] >> Failed to read fstab: " .. err)
else
  local buffer = ""
  repeat
    local data = handle.read(0xFFFF)
    buffer = buffer .. (data or "")
  until not data
  handle.close()

  local ok, err = load("return " .. buffer, "=kernel.parse_fstab", "bt", _G)
  if not ok then
    kernel.log("[INIT] >> Failed to parse fstab: " .. err)
  else
    fstab = ok()
  end
end

for k, v in pairs(fstab) do
  for a, t in component.list() do
    if a == k and t == "filesystem" then
      fs.mount(k, fstab[v])
    end
  end
end

kernel.log("[INIT] >> Setting up utilities")

kernel.log("util: loadfile")
function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  checkArg(2, mode, "string", "nil")
  checkArg(3, env, "table", "nil")
  local file = cleanPath(file)
  local mode = mode or "bt"
  local env = env or _G
  kernel.log("[INIT] >> loadfile: loading " .. file .. " with mode " .. mode)
  local handle, err = fs.open(file, "r")
  if not handle then
    return false, err
  end

  local data = ""
  repeat
    local d = handle.read(math.huge)
    data = data .. (d or "")
  until not d

  handle.close()

  return load(data, "=" .. file, mode, env)
end

kernel.log("[INIT] >> util: table.new")
function table.new(...)
  local tbl = {...} or {}
  return setmetatable(tbl, {__index = table})
end

kernel.log("[INIT] >> util: table.copy")
function table.copy(tbl)
  checkArg(1, tbl, "table")
  local rtn = {}
  for k,v in pairs(tbl) do
    rtn[k] = v
  end
  return rtn
end

kernel.log("[INIT] >> util: table.serialize")
function table.serialize(tbl) -- Readability is not a strong suit of this function's output.
  checkArg(1, tbl, "table")
  local rtn = "{"
  for k, v in pairs(tbl) do
    if type(k) == "string" then
      rtn = rtn .. "[\"" .. k .. "\"] = "
    else
      rtn = rtn .. "[" .. tostring(k) .. "] = "
    end
    if type(v) == "table" then
      rtn = rtn .. table.serialize(v)
    elseif type(v) == "string" then
      rtn = rtn .. "\"" .. tostring(v) .. "\""
    else
      rtn = rtn .. tostring(v)
    end
    rtn = rtn .. ","
  end
  rtn = rtn .. "}"
  return rtn
end

kernel.log("[INIT] >> util: table.iter")
function table.iter(tbl) -- Iterate over the items in a table
  checkArg(1, tbl, "table")
  local i = 1
  return setmetatable(tbl, {__call = function()
    if tbl[i] then
      i = i + 1
      return tbl[i - 1]
    else
      return nil
    end
  end})
end

kernel.log("[INIT] >> util: string.tokenize")
function string.tokenize(sep, ...)
  checkArg(1, sep, "string")
  local line = table.concat({...}, sep)
  local words = table.new()
  for word in line:gmatch("[^" .. sep .. "]+") do
    words:insert(word)
  end
  local i = 1
  setmetatable(words, {__call = function() -- iterators! they're great!
    if words[i] then
      i = i + 1
      return words[i - 1]
    else
      return nil
    end
  end})
  return words
end

kernel.log("[INIT] >> util: os.sleep")
local pullSignal = computer.pullSignal
function os.sleep(time)
  local dest = uptime() + time
  repeat
    pullSignal(dest - uptime())
  until uptime() >= dest
end

kernel.log("[INIT] >> util: fs.clean")
function fs.clean(path)
  checkArg(1, path, "string")
  return cleanPath(path)
end

kernel.log("[INIT] >> Initializing fancy event handling")
do
  _G.event = {}
  local pullSignal, pushSignal = computer.pullSignal, computer.pushSignal

  event.push = function(e, ...)
    kernel.log("events: Pushing signal " .. e)
    pushSignal(e, ...)
  end

  local listeners = {
    ["component_added"] = function(addr, ctype)
      if ctype == "filesystem" then
        fs.mount(addr)
      elseif ctype == "eeprom" then
        package.loaded["eeprom"] = kernel.__component.proxy(addr)
      end
      pushSignal("device_added", addr, ctype) -- for devfs processing. Bit hacky.
    end,
    ["component_removed"] = function(addr, ctype)
      if ctype == "filesystem" then
        fs.unmount(addr)
      elseif ctype == "eeprom" then
        package.loaded["eeprom"] = nil
      end
      pushSignal("device_removed", addr) -- again, for devfs processing, bit hacky, yadda yadda yadda
    end
  }

  event.listen = function(evt, func)
    checkArg(1, evt, "string")
    checkArg(2, func, "function")
    if listeners[evt] then
      return false, "Event listener already in place for event " .. evt
    else
      listeners[evt] = func
      return true
    end
  end

  event.cancel = function(evt)
    checkArg(1, evt, "string")
    if not listeners[evt] then
      return false, "No event listener for event " .. evt
    else
      listeners[evt] = nil
      return true
    end
  end

  event.pull = function(filter, timeout)
    checkArg(1, filter, "string", "nil")
    checkArg(2, timeout, "number", "nil")
--    kernel.log("events: pulling event " .. (filter or "<any>") .. ", timeout " .. (tostring(timeout) or "none"))
    if timeout then
      local e = {pullSignal(timeout)}
--      kernel.log("events: got " .. (e[1] or "nil"))
      if listeners[e[1]] then
        listeners[e[1]](table.unpack(e, 2, #e))
      end
      if e[i] == filter or not filter then
        return table.unpack(e)
      end
    else
      local e = {}
      repeat
        e = {pullSignal()}
--        kernel.log("events: got " .. e[1])
        if listeners[e[1]] then
          listeners[e[1]](table.unpack(e, 2, #e))
        end
      until e[1] == filter or filter == nil
      return table.unpack(e)
    end
  end
end

kernel.log("[mineVM] >> Initializing virtual components")
do
  local vcomponents = {}

  local list, invoke, proxy, comtype = component.list, component.invoke, component.proxy, component.type

  local ps = event.push

  function component.create(componentAPI)
    checkArg(1, componentAPI, "table")
    kernel.log("[mineVM] >> vcomponent: Adding component: type " .. componentAPI.type .. ", addr " .. componentAPI.address)
    vcomponents[componentAPI.address] = componentAPI
    ps("component_added", componentAPI.address, componentAPI.type)
  end

  function component.remove(addr)
    if vcomponents[addr] then
      ps("component_removed", vcomponents[addr].address, vcomponents[addr].type)
      vcomponents[addr] = nil
      return true
    end
    return false
  end

  function component.list(ctype, match)
    local matches = {}
    for k,v in pairs(vcomponents) do
      if v.type == ctype or not ctype then
        matches[v.address] = v.type
      end
    end
    local o = list(ctype, match)
    local i = 1
    local a = {}
    for k,v in pairs(matches) do
      a[#a+1] = k
    end
    for k,v in pairs(o) do
      a[#a+1] = k
    end
    local function c()
      if a[i] then
        i = i + 1
--        kernel.log(a[i - 1] .. " " .. (matches[a[i - 1]] or o[a[i - 1]]))
        return a[i - 1], (matches[a[i - 1]] or o[a[i - 1]])
      else
        return nil
      end
    end
    return setmetatable(matches, {__call = c})
  end

  function component.invoke(addr, operation, ...)
    checkArg(1, addr, "string")
    checkArg(2, operation, "string")
    if vcomponents[addr] then
--      kernel.log("vcomponent: " .. addr .. " " .. operation)
      if vcomponents[addr][operation] then
        return vcomponents[addr][operation](...)
      end
    end
    return invoke(addr, operation, ...)
  end

  function component.proxy(addr)
    checkArg(1, addr, "string")
    if vcomponents[addr] then
      return vcomponents[addr]
    else
      return proxy(addr)
    end
  end

  function component.type(addr)
    checkArg(1, addr, "string")
    if vcomponents[addr] then
      return vcomponents[addr].type
    else
      return comtype(addr)
    end
  end

  kernel.__component = component
end

kernel.log("[INIT] >> Initializing device FS")
do
  local dfs = {}

  local devices = {}

  local handles = {}

  -- Generate a component address --
  local s = {4,2,2,2,6}
  local addr = ""
  local p = 0

  for _,_s in ipairs(s) do
    if #addr > 0 then
      addr = addr .. "-"
    end
    for _=1, _s, 1 do
      local b = math.random(0, 255)
      if p == 6 then
        b = (b & 0x0F) | 0x40
      elseif p == 8 then
        b = (b & 0x3F) | 0x80
      end
      addr = addr .. ("%02x"):format(b)
      p = p + 1
    end
  end

  dfs.type = "filesystem"
  dfs.address = addr

  local types = {
    ["filesystem"] = "fs",
    ["gpu"] = "gpu",
    ["screen"] = "scrn",
    ["keyboard"] = "kb",
    ["eeprom"] = "eeprom",
    ["redstone"] = "rs",
    ["computer"] = "comp",
    ["disk_drive"] = "sr",
    ["internet"] = "inet",
    ["modem"] = "mnet"
  }

  local function addDfsDevice(addr, dtype)
    if addr == dfs.address then return end
  --  kernel.log(addr .. " " .. dtype)
    local path = "/" .. (types[dtype] or dtype)
    if dtype == "filesystem" and kernel.__component.invoke(addr, "getLabel") == "devfs" then
      return
    end
    local n = 0
    for k,v in pairs(devices) do
      if v.proxy and v.path and v.proxy.address then
        if v.proxy.address == addr then
          return
        end
        if v.proxy.type == dtype then
          n = n + 1
        end
      end
    end
    path = path .. n
    kernel.log("[INIT] >> devfs: adding device " .. addr .. " at /dev" .. path)
    devices[#devices + 1] = {path = path, proxy = kernel.__component.proxy(addr)}
  end

  event.listen("device_added", addDfsDevice)

  local function resolveDevice(d)
    for k,v in pairs(devices) do
      if v.path == d then
        return v
      end
    end
    return false, "No such device"
  end

  local function makeHandleEEPROM(eepromProxy, mode)
    checkArg(1, eepromProxy, "table")
    checkArg(2, mode, "string", "nil")
    if eepromProxy.type ~= "eeprom" then return false, "Device is not an EEPROM" end
    local d = {}
    function d:read()
      return eepromProxy.get(), "Failed to read EEPROM"
    end
    handles[#handles + 1] = d
    return d, #handles
  end

  function dfs.open(dev, mode)
    checkArg(1, dev, "string")
    checkArg(2, mode, "string", "nil")
    local device = resolveDevice(dev)
    if device.proxy.type == "eeprom" then
      local handle = makeHandleEEPROM(device, mode)
      return handle
    else
      return false, "Only EEPROMs are currently supported for opening"
    end
  end

  function dfs.isDirectory(d)
    checkArg(1, d, "string")
    if d == "/" then
      return true
    else
      return false
    end
  end

  function dfs.exists(f)
    checkArg(1, f, "string")
    kernel.log("[INIT] >> devfs: checking existence " .. f)
    if resolveDevice(f) or fs.clean(f) == "/" then
      return true
    else
      return false
    end
  end

  function dfs.list(p)
    checkArg(1, p, "string")
    local l = {}
    if not dfs.isDirectory(p) then
      return false, "Not a directory"
    end
    for k,v in pairs(devices) do
      l[#l + 1] = fs.clean(v.path):sub(#p + 1)
    end
    return l
  end

  function dfs.permissions()
    return 0
  end

  function dfs.lastModified()
    return 0
  end

  function dfs.close(num)
    handles[num] = nil
  end

  function dfs.spaceTotal()
    return 1024
  end

  function dfs.isReadOnly()
    return true
  end

  function dfs.getLabel() return "devfs" end
  function dfs.setLabel() return true end

  component.create(dfs)
  fs.mount(dfs.address, "/dev")

  for addr, ctype in component.list() do
    addDfsDevice(addr, ctype)
  end

  _G.devfs = {
    getAddress = function(device)
      local proxy = resolveDevice(device)
      return proxy.address
    end,
    poke = function(device, operation, ...)
      local proxy = resolveDevice(device)
      if proxy[operation] then
        return proxy[operation](...)
      end
    end
  }
end

kernel.log("[INIT] >> Initializing cooperative scheduler")
do
  local tasks = {}
  local pid = 1
  local currentpid = 0
  local timeout = (type(flags.processTimeout) == "number" and flags.processTimeout) or 0.10
  local freeMemory = computer.freeMemory
    
  function os.spawn(func, name)
    checkArg(1, func, "function")
    checkArg(2, name, "string")
    if freeMemory() < 128 then
      error("Out of memory", -1)
    end
    kernel.log("[INIT] >> scheduler: Spawning task " .. tostring(pid) .. " with ID " .. name)
    tasks[pid] = {
      coro = coroutine.create(func),
      id = name,
      pid = pid,
      parent = currentpid
    }
    pid = pid + 1
    return pid - 1
  end

  function os.kill(pid)
    checkArg(1, pid, "number")
    if not tasks[pid] then return false, "No such process" end
    if pid == 1 then return false, "Cannot kill init" end
    kernel.log("[INIT] >> scheduler: Killing task " .. tasks[pid].id .. " (PID ".. tostring(pid) .. ")")
    tasks[pid] = nil
  end

  function os.tasks()
    local r = {}
    for k,v in pairs(tasks) do
      r[#r + 1] = k
    end
    return r
  end

  function os.pid()
    return currentpid
  end

  function os.info(pid)
    checkArg(1, pid, "number", "nil")
    local pid = pid or os.pid()
    if not tasks[pid] then return false, "No such process" end
    return {name = tasks[pid].id, parent = tasks[pid].parent, pid = tasks[pid].pid}
  end
  
  function os.exit()
    os.kill(currentpid)
    coroutine.yield()
  end
  
  function os.start() -- Start the scheduler
    os.start = nil
    while #tasks > 0 do
      local eventData = {pullSignal(timeout)}
      for k, v in pairs(tasks) do
        if freeMemory() < 256 then
          error("Out of memory", -1)
        end
        if v.coro and coroutine.status(v.coro) ~= "dead" then
          currentpid = k
--          kernel.log("Current: " .. tostring(k))
          local ok, err = coroutine.resume(v.coro, table.unpack(eventData))
          if not ok and err then
            local err = "ERROR IN THREAD " .. tostring(k) .. ": " .. v.id .. "\n" .. debug.traceback(err, 1)
            kernel.log(err)
            print(err)
            kernel.log("scheduler: Task " .. v.id .. " (PID " .. tostring(k) .. ") died: " .. err)
            tasks[k] = nil
          end
        elseif v.coro then
          kernel.log("scheduler: Task " .. v.id .. " (PID " .. tostring(k) .. ") died")
          tasks[k] = nil
        end
      end
    end
    kernel.log("scheduler: all tasks exited")
    shutdown()
  end
end

kernel.log("[INIT] >> Loading: init.lua (mineCORE SysBoot File) " .. init)
local ok, err = loadfile(init)
if not ok then
  error(err, -1)
end

--local s, e = pcall(ok, flags.runlevel)
local s, e = os.spawn(function()return ok(flags.runlevel)end, "[init]")
if not s then
  error(e, -1)
end

os.start()
