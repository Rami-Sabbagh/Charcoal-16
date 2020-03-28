local libraryPath = string.sub((...), 1, -1-string.len(".display"))

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

local display = class("charcoal.Display")

function display:initialize(properties)
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

    --The resolution of the canvas
    self.width, self.height = self.characterWidth*self.columns, self.characterHeight*self.rows

    --The canvas of the display
    self.canvas = love.graphics.newCanvas(self.width, self.height, { dpiscale=1 })
    self.canvas:setFilter("nearest")

    --The tint of the rendered display
    self.tint = {0, 1, 0, 1}

    --Wrap render call
    self.wrappedRender = function() self:render(self.memory, self.startAddress) end
end

function display:render(memory, startAddress)
    love.graphics.clear(0,0,0,1)
    love.graphics.setColor(1,1,1,1)

    for j=0, self.rows-1 do
        for i=0, self.columns-1 do
            local characterID = memory[startAddress+i+j*self.columns]
            love.graphics.draw(self.font, self.charactersQuads[characterID], i*self.characterWidth, j*self.characterHeight)
        end
    end
end

function display:draw(x, y, w, h, memory, startAddress)
    self.memory, self.startAddress = memory, startAddress
    self.canvas:renderTo(self.wrappedRender)

    love.graphics.setColor(0,0,0, 1)
    love.graphics.rectangle("fill", x, y, w, h)

    local scale = math.floor(math.min(w/self.width, h/self.height))

    love.graphics.setColor(self.tint)
    love.graphics.draw(self.canvas, x+(w-self.width*scale)/2, y+(h-self.height*scale)/2, 0, scale, scale)
end

return display