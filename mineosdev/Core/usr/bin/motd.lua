-- Serve a random MOTD --

local computer = require("computer")

local motds = {
  "Kolibra Studios 2022. All rights reserved.",
}

print(("="):rep(32))
print(shell._VERSION .. " on " .. kernel._VERSION .. " - " .. tostring(math.floor(computer.totalMemory()/1024)) .. "k RAM")
print(motds[math.random(1, #motds)])
print(("="):rep(32))
