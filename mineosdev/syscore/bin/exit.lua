-- logout: Kill the shell, spawn a login screen

for k,v in pairs(os.tasks()) do
  if os.info(v).name == "/bin/sh.lua" then
    os.kill(v)
  end
end

os.kill(os.pid())
