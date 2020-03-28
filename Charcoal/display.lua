local libraryPath = string.sub((...), 1, -1-string.len(".display"))

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

local display = class("charcoal.Display")

function display:initialize(properties)
    --The resolution of the canvas
    self.width, self.height = properties.width, properties.height

    --The columns and rows of the characters display
    self.columns, self.rows = properties.columns, properties.rows

    --The font of the display, an image
    self.font = properties.font

    self.fontWidth = self.font:getWidth()
    self.fontHeight = self.font:getHeight()
    self.characterWidth = self.fontWidth/16
    self.characterHeight = self.fontHeight/16
    self.charactersQuads = {}
    for j=0, 15 do
        for i=0, 15 do
            self.charactersQuads[i + j*16] = love.graphics.newQuad(i*self.characterWidth, j*self.characterHeight,
                self.characterWidth, self.characterHeight, self.fontWidth, self.fontHeight)
        end
    end

    --The canvas of the display
    self.canvas = love.graphics.newCanvas(self.width, self.height, { dpiscale=1 })
    self.canvas:setFilter("nearest")

    --The tint of the rendered display
    self.tint = {0, 1, 0, 1}
end

function display:render()
    love.graphics.setCanvas(self.canvas)

    love.graphics.clear(0,0,0,1)

    for j=0, self.rows-1 do
        for i=0, self.columns-1 do
            love.graphics.setColor(1,1,1,1)
            love.graphics.draw(self.font, self.charactersQuads[(i+j*self.columns)%256], i*self.characterWidth, j*self.characterHeight)
        end
    end

    love.graphics.setCanvas()
end

function display:draw()
    self:render()

    love.graphics.setColor(self.tint)
    love.graphics.draw(self.canvas, 0,0, 0, 2,2)
end

return display