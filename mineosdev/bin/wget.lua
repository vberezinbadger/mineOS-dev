-- wget: Download files from the internet --

local args, options = shell.parse(...)

local netutils = require("netutils")

local usage = [[wget (c) 2020 Ocawesome101 under the MIT License.
usage: wget URL FILE

wget will attempt to guess a destination file if none is specified.
]]

if #args < 1 or options.h or options.help then
  return print(usage)
end

local url = args[1]
local out = args[2] or nil
if not out then
  print("No outfile specified; guessing from URL")
  local tok = string.tokenize("/", url)
  out = tok[#tok]
end

local out = shell.resolve(out)

print("Downloading " .. url .. " as " .. out)
local ok, err = netutils.download(url, out)
if not ok and err then
  return print(err)
end
print("Done.")
