local libraryPath = ...

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

--Require the Charcoal modules
local Display = require(libraryPath..".display")

--The Charcoal class
local Charcoal = class("charcoal.Charcoal")

function Charcoal:initialize()
    self.display = Display {
        width = 256,
        height = 256,

        columns = 42,
        rows = 28,

        font = love.graphics.newImage(libraryPath:gsub("%.", "/").."/font.png")
    }
end

function Charcoal:update(dt)

end

function Charcoal:draw()
    self.display:draw()
end

return Charcoal