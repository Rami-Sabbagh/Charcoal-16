local libraryPath = ...

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

--Require the Charcoal modules
local Display = require(libraryPath..".display")
local Processor = require(libraryPath..".processor")

--The Charcoal class
local Charcoal = class("charcoal.Charcoal")

function Charcoal:initialize()
    self.processor = Processor()

    local systemImage = assert(love.filesystem.newFile("debug.bin", "r"))
    self.processor:loadImage(systemImage)
    systemImage:close()

    self.display = Display {
        columns = 42,
        rows = 28,

        font = love.graphics.newImage(libraryPath:gsub("%.", "/").."/font.png"),
        palettes = love.image.newImageData(libraryPath:gsub("%.", "/").."/palettes.png")
    }

    --Temporary
    self.frequency = 1000 --1 KHz
    self.cycleTime = 1/self.frequency
    self.clock = 0

    self.memory = self.processor:getMemory()
end

function Charcoal:update(dt)
    --if not love.keyboard.isDown("space") then return end
    self.clock = self.clock + dt

    local cyclesToExecute = math.floor(self.clock/self.cycleTime)
    self.clock = self.clock - cyclesToExecute*self.cycleTime

    for _=1, cyclesToExecute do
        self.processor:executeCycle()
    end
end

function Charcoal:draw(x,y, w,h)
    self.display:draw(x,y, w,h, self.memory, 0xF6CA, 0xFFFA)
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