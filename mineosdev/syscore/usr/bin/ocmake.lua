-- ocmake: kinda-sorta-reimplementation of make --
local args, options = shell.parse(...)

local config = require("config")
local target = args[1] or "all"

local dir = os.getenv("PWD")

if not fs.exists(fs.clean(dir .. "/OMakefile")) then
  print("ocmake: *** No OMakefile found. Stop.")
  return
end

local makefile = config.load(fs.clean(dir .. "/OMakefile"))

if not makefile[target] then
  print("ocmake: *** No rule to make target '" .. target .. "'. Stop.")
  return
end

local function make(t)
  if not makefile[t] then
    print("ocmake: *** No rule to make target '" .. t .. "'")
  end
  if makefile[t].deps then
    for dep in table.iter(makefile[t].deps) do
      local s = make(dep)
      if not s then return false end
    end
  end
  if makefile[t].exec then
    for command in table.iter(makefile[t].exec) do
      print(command)
      local ok, ret = pcall(function()return shell.execute(command)end)
      if not ok then
        print("ocmake: *** Target '" .. t .. "' failed: " .. ret)
        return false
      end
      print(ret)
    end
  end
  return true
end

make(target)
