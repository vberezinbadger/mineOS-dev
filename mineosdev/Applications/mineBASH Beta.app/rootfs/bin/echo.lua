-- echo: print input to output --

local args, options = shell.parse(...)

local notrail = options.n or false
local help = options.help or false

local usage = [[echo (c) 2020 Ocawesome101 under the MIT License.
usage: echo [LONG-OPTION]
   or: echo [SHORT-OPTION]... [STRING]...

   -n         do not output the trailing newline
      --help  display this help and exit
]]

if help then
  print(usage)
  return
end

local str = table.concat(args, " ")

if str ~= "" and str ~= " " then
  print(str)
end

if not notrail then
  io.write("\n")
end
