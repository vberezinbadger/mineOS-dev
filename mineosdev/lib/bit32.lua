-- API for compatibility between Lua 5.2 and Lua 5.3 --

if bit32 then return bit32 end

-- Loaded from a string so this will still parse on Lua 5.2
return load([[
local bit32 = {}

local function checkNumbers(...)
  local args = {...}
  for k,v in pairs(args) do
    checkArg(k, v, "number")
  end
end

local function band(tbl, i)
  if tbl[i + 1] then
    return tbl[i] & band(tbl, i + 1)
  else
    return (tbl[i] or nil)
  end
end

local function bxor(tbl, i)
  if tbl[i + 1] then
    return tbl[i] ~ band(tbl, i + 1)
  else
    return (tbl[i] or nil)
  end
end

function bit32.arshift()
  error("bit32.arshift not implemented")
end

function bit32.band(...)
  checkNumbers(...)
  local args = {...}
  return band(args, 1)
end

function bit32.bnot(x)
  checkNumbers(x)
  return ~ x
end

function bit32.btest(...)
  local is = bit32.band(...)
  return is ~= 0
end

function bit32.bxor(...)
  checkNumbers(...)
  return bxor({...}, 1)
end

function bit32.extract()
  error("bit32.extract not implemented")
end

function bit32.replace()
  error("bit32.replace not implemented")
end

function bit32.lrotate()
  error("bit32.lrotate not implemented")
end

function bit32.lshift(x, disp)
  checkNumbers(x, disp)
  return x << disp
end

function bit32.rrotate()
  error("bit32.rrotate not implemented")
end

function bit32.rshift(x, disp)
  checkNumbers(x, disp)
  return x >> disp
end

return bit32
]], "=/lib/bit32.lua", "t", {})
