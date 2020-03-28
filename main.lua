local Charcoal = require("Charcoal")

--The charcoal instance
local charcoal

--The dimensions of the window
local width, height = 256, 256

function love.load()
    --Create the charcoal machine
    charcoal = Charcoal()

    width, height = love.graphics.getDimensions()
end

function love.update(dt)
    charcoal:update(dt)
end

function love.draw()
    charcoal:draw(0,0, width, height)
end

function love.resize(w, h)
    width, height = w, h
end