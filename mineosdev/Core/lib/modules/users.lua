-- User system --

local users = {}

local user = "root"
local uid = 0

local unicode = require("unicode")
local config = require("config")
local sha, e = require("sha256")
kernel.log(tostring(sha) .. " " .. tostring(e))
if e then
  error(e, -1)
end

kernel.log("Users: Reading /etc/passwd")
local passwd, err = config.load("/etc/passwd")
if not passwd then
  passwd = {}
  kernel.log("WARNING: " .. err)
end

local users = {}

local function encrypt(str, salt)
  local result = sha.sha256(str .. salt)
  return result
end

function users.login(name)
  if not passwd[name] then
    return false, "No such user"
  end
  kernel.log("Users: Attempting login as " .. name)
  local tries = 3
  local salt = passwd[name].salt
  while tries > 0 do
    io.write("Password: ")
    local password = read(" ")
    local password = encrypt(password, salt or "")
    if passwd[name].pass == password then
      user = name
      uid = passwd[name].uid
      return true
    else
      tries = tries - 1
    end
  end
  kernel.log("Users: maximum login attempts exceeded")
  print("Exceeded the number of login attempts. Repeat later.")
  return false
end

function users.user()
  return user
end

function users.uid()
  return uid
end

function users.list()
  local u = {}
  for k,_ in pairs(passwd) do
    u[#u + 1] = k
  end
  return u
end

function users.home()
  if user ~= "root" or uid ~= 0 then
    return "/home/" .. user
  else
    return "/root"
  end
end

function users.adduser(name)
  checkArg(1, name, "string")
  if passwd[name] then
    return false, "User already exists"
  end
  kernel.log("Users: adding user " .. name)
  local password = ""
  repeat
    io.write("Password: ")
    password = read(" ")
  until password ~= ""
  local salt = ""
  for i=1, 64, 1 do
    salt = salt .. unicode.char(math.random(32, 0x28FF))
  end
  password = encrypt(password, salt)
  local u = 0
  for k, v in pairs(passwd) do
    if v.uid > u then
      u = v.uid
    end
  end
--  local tsalt = salt:gsub(".", function(a)return string.format("%02x", string.byte(a))end)
  passwd[name] = {
    uid = u + 1,
    pass = password,
    salt = salt
  }
  kernel.log("users: saving /etc/passwd")
  config.save(passwd, "/etc/passwd")
  return true
end

function users.deluser(name)
  checkArg(1, name, "string")
  if name == "root" then
    return false, "[WARNING] >> Cannot remove the root user"
  end
  if not passwd[name] then
    return false, "No such user"
  end
  kernel.log("Users: removing user " .. name)
  kernel.log("Users: authenticating removal")
  if uid ~= 0 or user ~= "root" then -- You aren't root, we need the password of the user you're deleting
    local tries = 3
    while tries > 0 do
      io.write("Password: ")
      local password = read(" ")
      password = encrypt(password, passwd[name].salt)
      if password == passwd[mame].password then
	break
      end
      tries = tries - 1
    end
    if tries == 0 then
      print("Authentication failed.")
      kernel.log("Users: authentication failed")
      return false, "User authentication failed"
    end
  else -- You are root, but we still need your password just to be safe
    local tries = 3
    while tries < 0 do
      io.write("Password: ")
      local password = read(" ")
      password = encrypt(password, passwd["root"].salt)
      if password == passwd[name].password then
	break
      end
      tries = tries - 1
    end
    if tries == 0 then
      print("Authentication failed.")
      kernel.log("users: authentication failed")
      return false, "Authentication failed"
    end
  end
  kernel.log("users: saving /etc/passwd")
  passwd[name] = nil
  config.save(passwd, "/etc/passwd")
  return true, "User removed"
end

package.loaded["users"] = users
