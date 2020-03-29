local libraryPath = ...

local bit = require("bit")
local band, rshift = bit.band, bit.rshift

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

--Require the Charcoal modules
local Display = require(libraryPath..".display")
local Gamepad = require(libraryPath..".gamepad")
local Processor = require(libraryPath..".processor")
local Speaker = require(libraryPath..".speaker")

--The Charcoal class
local Charcoal = class("charcoal.Charcoal")

function Charcoal:initialize()
    self.processor = Processor()

    local systemImage = assert(love.filesystem.newFile("debug.bin", "r"))
    self.processor:loadImage(systemImage)
    systemImage:close()

    self.display = Display{
        columns = 42,
        rows = 28,

        font = love.graphics.newImage(libraryPath:gsub("%.", "/").."/font.png"),
        palettes = love.image.newImageData(libraryPath:gsub("%.", "/").."/palettes.png")
    }

    self.gamepad1 = Gamepad{
        keymap = {
            --A, B, Start, Select, Up, Down, Left, Right
            "z", "x", "c", "v", "up", "down", "left", "right"
        }
    }

    self.gamepad2 = Gamepad{
        keymap = {
            --A, B, Start, Select, Up, Down, Left, Right
            "kpenter", "kp+", "kp9", "kp*", "kp5", "kp2", "kp1", "kp3"
        }
    }

    self.speaker = Speaker()

    --Temporary
    self.frequency = 1000000 --1 MHz
    self.cycleTime = 1/self.frequency
    self.clock = 0

    self.memory = self.processor:getMemory()
end

function Charcoal:update(dt)
    local speakerShort = self.processor:getShort(0xFFFC)
    local speakerWaveform = rshift(speakerShort, 14)
    local speakerVolume = band(rshift(speakerShort, 11), 0x3)
    local speakerSamplesForHalfwave = band(speakerShort, 0x07FF)
    self.speaker:update(dt, speakerWaveform, speakerSamplesForHalfwave, speakerVolume)

    --if not love.keyboard.isDown("space") then return end
    self.clock = self.clock + dt

    local cyclesToExecute = math.floor(self.clock/self.cycleTime)
    self.clock = self.clock - cyclesToExecute*self.cycleTime

    local gamepadByte1 = self.gamepad1:getByte()
    local gamepadByte2 = self.gamepad2:getByte()

    for _=1, cyclesToExecute do
        self.memory[0xFFFE] = gamepadByte1
        self.memory[0xFFFF] = gamepadByte2
        self.processor:executeCycle()
    end
end

function Charcoal:draw(x,y, w,h)
    self.display:draw(x,y, w,h, self.memory, 0xF6CA, 0xFFFA, 0xFFFB)
end

--[[
Memory Layout:
--------------
0x0000 -> Program start
0xF6CA -> VRAM start
0xFFFA -> Border color & palette ID
0xFFFB -> VRAM offset
0xFFFC & 0xFFFD -> Speaker frequency
0xFFFE -> Gamepad 1
0xFFFF -> Gamepad 2
]]

return Charcoal