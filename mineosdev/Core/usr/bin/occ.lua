-- occ (c) 2020 Ocawesome101 under the MIT License. --
--[[
OCC is a basic ANSI C compiler, written for Open Kernel 2.

Supported Preprocessor Features:
#include "<file.h>" -- Checks for a header file in /usr/include.
#define CONSTANT <value> -- Define a constant CONSTANT as <value>.

Planned Preprocessor Features:
#ifdef CONSTANT
#ifndef CONSTANT

Run `man okstdclib` for information on the standard library segments included with Open Kernel.
]]

local args, options = shell.parse(...)

if #args < 1 then
  return print("occ: fatal error: no input files\ncompilation terminated.")
end

---------------------------------------- Helpers ------------------------------------------
local function depPath(include)
  if fs.exists("/usr/include/" .. include) then
    return "/usr/include/" .. include
  else
    return false, "File /usr/include/" .. include .. " not found"
  end
end

local function loadDep(include)
  local path, err = depPath(include)
  if not path then
    return false, err
  end
  local depHandle = io.open(path, "r")
  local depData = depHandle:readAll()
  depHandle:close()
  return depData
end

local function invalidSyntaxError(line, num, err)
  local err = "Invalid syntax!\nat line " .. tostring(num) .. "\nat " .. line .. ": " .. err
  return err
end
-------------------------------------------------------------------------------------------

-- Get all the file data. This will be operated on, so to speak, and then put into the output file when we're done. --
local path = shell.resolve(args[1])
if not fs.exists(path) then
  return print("occ: error: " .. args[1] .. ": No such file\nocc: fatal error: no input files\ncompilation terminated.")
end

local handle = io.open(path, "r")
local fileData = handle:readAll()
handle:close()

-----=====-----

-------------------------------------- Preprocessor ---------------------------------------

local lines = {}

local linesAreHeader = 0 -- The number of lines that are header files

print("occ: preprocessing file")
for line in fileData:gmatch("[^\n]+") do
  local operation = ""
  local operated = false
  for word in line:gmatch("[^ ]+") do
    if word == "#include" then
      operation = "include"
    elseif word == "#define" then
      operation = "define"
    else
      if operation == "include" then
        if word:sub(1, 1) == "<" and word:sub(-1) == ">" then
          local header, err = loadDep(word:sub(2, -2))
          if not header then
            print("occ: fatal error: " .. err)
            print("compilation terminated.")
            return
          end
          local l = 1
          local sl = linesAreHeader
          for ln in header:gmatch("[^\n]+") do
            if not ln:find("[{}]") and not ln:find("//") and ln:sub(-1) ~= ";" then
              return print(invalidSyntaxError(ln, l - sl, "expected ';'"))
            end
            lines[#lines + 1] = ln
            linesAreHeader = linesAreHeader + 1
          end
        else
          print("WARNING: invalid header " .. word)
        end
        operated = true
      end
      operation = ""
    end
  end
  if not operated then
    lines[#lines + 1] = line
  end
end

-- Check syntax. Very basic. --
local linenum = 1
for line in table.iter(lines) do
  if not line:find("[{}]") and not line:find("//") then
    if line:sub(-1) ~= ";" then
      return print(invalidSyntaxError(line, linenum - linesAreHeader, "expected ';'"))
    end
  end
  linenum = linenum + 1
end

-------------------------------------------------------------------------------------------

print("occ: preprocessor finished")

-------------------------------------- The Compiler ---------------------------------------
-- This is really just a syntax converter.

print("occ: compiling")

local compilerWords = {
  ["int"] = true,
  ["void"] = true,
  ["const"] = true,
  ["char*"] = true
}

local output = {}

local inExec = false
local ignore = false
for line in table.iter(lines) do
  local tline, outline = {}, ""
  for word in line:gmatch("[^ ]+") do
    print(word)
    tline[#tline + 1] = word
    for w,_ in next, compilerWords do
      if word:find(w .. " ") then -- fragile
        ignore = true
        print("occ: ignoring " .. word)
      end
    end
    if compilerWords[word] then
      ignore = true
      print("occ: ignoring " .. word)
    end
    if ignore then
      ignore = false
    elseif word:match("%(") and not inExec then
      outline = outline .. "local function " .. word
    elseif word == "if" then
      outline = outline .. "if "
    elseif word == "while" then
      outline = outline .. "while "
    elseif word == "{" then
      if tline[1] == "while" then
        outline = outline .. " do"
      end
    elseif word == "}" then
      outline = "end"
    else
      outline = outline .. " " .. word
    end
  end
  outline = outline:gsub("//", "--")
  print(outline)
  output[#output + 1] = outline .. "\n"
end

print("occ: writing a.out")

local aout = shell.resolve("a.out")
local h = io.open(aout, "w")
for line in table.iter(output) do
  h:write(line)
end
h:close()
-------------------------------------------------------------------------------------------

print("occ: done.")
