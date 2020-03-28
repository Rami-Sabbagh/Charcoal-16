local libraryPath = string.sub((...), 1, -1-string.len(".gamepad"))

local bit = require("bit")
local lshift = bit.lshift

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

local gamepad = class("charcoal.Gamepad")

function gamepad:initialize(properties)
    self.keymap = properties.keymap
end

function gamepad:getByte()
    local byte = 0
    for i=0, 7 do
        if love.keyboard.isDown(self.keymap[i+1]) then
            byte = byte + lshift(1, i)
        end
    end
    return byte
end

return gamepad