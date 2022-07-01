local ok, err = loadfile("/bin/freeze.lua")
while true do
  os.spawn(ok, "/bin/freeze.lua")
end
