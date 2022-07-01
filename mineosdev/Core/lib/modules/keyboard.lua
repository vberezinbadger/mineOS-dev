-- Keyboard stuff. Enable this for OpenOS compatibility, else leave it. --

local event = require("event")

local keyboard = {}
keyboard.pressedChars = {}
keyboard.pressedCodes = {}

local function keydown(_, char, code)
  keyboard.pressedChars[char] = true
  keyboard.pressedCodes[code] = true
end

local function keyup(_, char, code)
  keyboard.pressedChars[char] = nil
  keyboard.pressedCodes[code] = nil
end

------------------------------------------------

event.listen("key_down", keydown)
event.listen("key_up", keyup)

package.loaded["base_keyboard"] = keyboard
