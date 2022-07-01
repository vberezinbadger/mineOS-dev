-- EXIT --
local computer = computer or require("computer")

kernel.log("Exiting in desktop...")
term.update()
computer.shutdown(false)
