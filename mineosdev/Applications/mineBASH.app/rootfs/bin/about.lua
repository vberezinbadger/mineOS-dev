-- About --

local args = {...} 

local computer = computer or require("computer")

if #args < 1 then
  error("Usage: about -core|-project")
  return false
end

if args[1] == "-core" then
  print("mineCORE, version 2.0 (channel: beta)")
  print("Kolibra Studios 2022. All rights reserved.")
  kernel.log("mineCORE, version 2.0 (channel: beta)")
  kernel.log("Kolibra Studios 2022. All rights reserved.")
elseif args[1] == "-project" then
  print("mineCORE - this is a new kernel that makes it easier to manage the system. It is also used in the MineOS operating system in the terminal.")
  print("Kolibra Studios 2022. All rights reserved.")
  kernel.log("mineCORE - this is a new kernel that makes it easier to manage the system. It is also used in the MineOS operating system in the terminal.")
  kernel.log("Kolibra Studios 2022. All rights reserved.")
else
  error("Usage: about -core|-project")
  return false
end
