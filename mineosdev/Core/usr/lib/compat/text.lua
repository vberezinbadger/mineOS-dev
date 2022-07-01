-- Compatibility with OpenOS --

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
  return string.tokenize(" ", str)
end

return t
