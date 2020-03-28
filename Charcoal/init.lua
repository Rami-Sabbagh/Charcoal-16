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
        palette = love.image.newImageData(libraryPath:gsub("%.", "/").."/palette.png")
    }

    --Temporary
    self.frequency = 1000 --1 KHz
    self.cycleTime = 1/self.frequency
    self.clock = 0

    self.memory = self.processor:getMemory()
    self.vramAddress = 0
end

function Charcoal:update(dt)
    --if not love.keyboard.isDown("space") then return end
    self.clock = self.clock + dt

    local cyclesToExecute = math.floor(self.clock/self.cycleTime)
    self.clock = self.clock - cyclesToExecute*self.cycleTime

    for i=1, cyclesToExecute do
        self.processor:executeCycle()
    end
end

function Charcoal:draw(x,y, w,h)
    self.display:draw(x,y, w,h, self.memory, self.vramAddress, self.vramAddress+42*28*2)
end

return Charcoal