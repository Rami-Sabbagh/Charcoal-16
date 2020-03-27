local Charcoal = require("Charcoal")

--The charcoal instance
local charcoal

function love.load()
    --Create the charcoal machine
    charcoal = Charcoal()
end

function love.update(dt)
    charcoal:update(dt)
end

function love.draw()
    charcoal:draw()
end