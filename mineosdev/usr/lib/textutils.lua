-- fancy things --

local tu = {}

function tu.tabbedPrint(tbl)
  checkArg(1, tbl, "table")
  local w,h = gpu.getResolution()
  local maxlen = 1
  for i=1, #tbl, 1 do
    if #tbl[i] > maxlen then
      maxlen = #tbl[i]
    end
  end
  maxlen = maxlen + 2 -- there should be space between this stuff
  local x = 1
  for i=1, #tbl, 1 do
    local s = tbl[i]
    while #s < maxlen do
      s = s .. " "
    end
    io.write(s)
  end
  if #tbl > 0 then
    io.write("\n")
  end
end

return tu
