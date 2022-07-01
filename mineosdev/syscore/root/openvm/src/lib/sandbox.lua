-- Sandboxing!
local sandbox = {}
sandbox.component = {}
local components = {}
function sandbox.component.list(id)
  checkArg(1, id, "string", "nil")
  local rtn = {}
  for k, v in pairs(components) do
    if k == id or not id then
      rtn[k] = v.type
    end
  end
  local i = 1
  local call = function()
    if rtn[i] then
      i = i + 1
      return rtn[i - 1]
    else
      return nil
    end
  end
  return setmetatable(rtn, {__call = call})
end
function sandbox.component.proxy(addr)
  checkArg(1, addr, "string")
  if components[addr] then
    return table.copy(components[addr])
  else
    return nil, "no such component"
  end
end
function sandbox.component.invoke(addr, operation, ...)
  checkArg(1, addr, "string")
  checkArg(1, operation, "string")
  if components[addr] then
    return components[addr][operation](...)
  else
    return nil, "no such component"
  end
end
function sandbox.component.type(addr)
  checkArg(1, addr, "string")
  if components[addr] then
    return components[addr].type
  else
    return nil, "no such component"
  end
end
function sandbox.component.slot(addr)
  checkArg(1, addr, "string")
  if components[addr] then
    return -1
  else
    return nil, "no such component"
  end
end
function sandbox.component.get(addr, ctype)
  for k, v in pairs(components) do
    if k:sub(1, #addr) == addr and v.type == ctype then
      return k
    end
  end
  return nil, "no such component"
end
sandbox.table = table.copy(table)
sandbox.table.copy, sandbox.table.iter, sandbox.table.serialize = nil, nil, nil
sandbox.string = table.copy(string)
sandbox.string.tokenize = nil
sandbox.math = table.copy(math)
sandbox.pcall = pcall
sandbox.xpcall = xpcall
sandbox.debug = table.copy(debug)
sandbox.assert = assert
sandbox.setmetatable = setmetatable
sandbox.getmetatable = getmetatable
sandbox.pairs = pairs
sandbox.ipairs = ipairs
sandbox.error = function(e, l)
  checkArg(1, e, "string")
  checkArg(2, l, "number", "nil")
  if l and l == -1 or l == "__KPANIC__" then
    l = 0
  end
  error(e, l)
end
sandbox.coroutine = table.copy(coroutine)
sandbox._VERSION = _VERSION
sandbox.unicode = table.copy(require("unicode"))
sandbox.computer = {}
local c = require("computer")
local event_queue = table.new()
function sandbox.computer.shutdown(b)
--  shutdown = true
end
function sandbox.computer.beep(a, b)
  return c.beep(a, b)
end
function sandbox.computer.freeMemory()
  return c.freeMemory()
end
function sandbox.computer.totalMemory()
  return c.totalMemory()
end
function sandbox.computer.pullSignal(t)
  if t and t == 0 then
    return
  else
    event_queue:insert(computer.pullSignal(t))
    local e = event_queue[1]
    if e then
      table.remove(event_queue, 1)
      return table.unpack(e or {})
    end
  end
end
function sandbox.computer.pushSignal(s, ...)
  checkArg(1, s, "string")
  table.insert(event_queue, {s, ...})
end
sandbox.tonumber = tonumber
sandbox.tostring = tostring
sandbox.select = select
sandbox.next = next
