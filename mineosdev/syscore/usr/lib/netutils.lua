-- Small collection of networking utilities that make life easier. --

local nu = {} -- Ni! Ni! Ouch! He said it! Oh no, I've just said it again! and again! ...

local internet = require("internet")
if not internet then
  return false, "netutils: An internet card is required"
end
local computer = require("computer")

function nu.download(url, dest)
  checkArg(1, url, "string")
  checkArg(2, dest, "string")
  local conn = internet.request(url)
  local time = computer.uptime()
  local ok, err = conn.finishConnect()
  local data = ""
  repeat
    local r = conn.read(math.huge)
    data = data .. (r or "")
  until not r
  conn.close()
  local handle, err = fs.open(dest, "w")
  if not handle then return false, err, print(err) end
  handle:write(data)
  handle:close()
end

return nu
