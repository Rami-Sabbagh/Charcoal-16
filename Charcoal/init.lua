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
        width = 256,
        height = 256,

        columns = 42,
        rows = 28,

        font = love.graphics.newImage(libraryPath:gsub("%.", "/").."/font.png"),

        memory = self.processor:getMemory(),
        firstAddress = 0
    }

    --Temporary
    self.frequency = 1000 --1 MHz
    self.cycleTime = 1/self.frequency
    self.clock = 0
end

function Charcoal:update(dt)
    self.clock = self.clock + dt

    local cyclesToExecute = math.floor(self.clock/self.cycleTime)
    self.clock = self.clock - cyclesToExecute*self.cycleTime

    for i=1, cyclesToExecute do
        self.processor:executeCycle()
    end
end

function Charcoal:draw()
    self.display:draw()
end

return Charcoal