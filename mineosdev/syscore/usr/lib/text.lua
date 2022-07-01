-- Turns out, this API is pretty useful :P --

local t = {}

function t.detab(str, width)
  checkArg(1, str, "string")
  checkArg(2, width, "number")
  return str:gsub("\t", (" "):rep(width))
end

function t.padRight(str, len)
  checkArg(1, str, "string")
  checkArg(2, len, "number")
  while #str < len do
    str = str .. " "
  end
  return str
end

function t.padLeft(str, len)
  checkArg(1, str, "string")
  checkArg(2, len, "number")
  while #str < len do
    str = " " .. str
  end
  return str
end

function t.tokenize(str)
  checkArg(1, str, "string")
  return string.tokenize(" ", str)
end

function t.longest(tbl)
  checkArg(1, tbl, "table")
  local len = 0
  for _,v in pairs(tbl) do
    if type(v) == "string" and #v > len then
      len = #v
    end
  end
  return len
end

return t
