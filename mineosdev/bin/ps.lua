-- ps: list running processes --

local processes = os.tasks()

print("PID  PARENT  NAME")
for _, pid in pairs(processes) do
  local pinfo = os.info(pid)
  local pid, par, nam = tostring(pinfo.pid), tostring(pinfo.parent), pinfo.name
  while #pid < 5 do
    pid = pid .. " "
  end
  while #par < 8 do
    par = par .. " "
  end
  print(pid .. par .. nam)
end
