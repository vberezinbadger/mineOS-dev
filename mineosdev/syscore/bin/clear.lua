-- clear: clear the screen --

local w,h = gpu.getResolution()
gpu.fill(1,1,w,h," ")
gpu.setCursor(1,1)
