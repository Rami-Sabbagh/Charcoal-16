local libraryPath = string.sub((...), 1, -1-string.len(".display"))

local bit = require("bit")
local band, rshift = bit.band, bit.rshift

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

    --An imagedata containing the palette
    self.paletteImageData, self.palettes = properties.palettes, {}
    for i=0, 0x7F do self.palettes[i] = {0,0,0, 1} end
    do
        local nextID=0
        self.paletteImageData:mapPixel(function(x,y, r,g,b,a)
            if nextID <= 0x7F then
                self.palettes[nextID] = {r,g,b, a}
                nextID = nextID + 1
            end
            return r,g,b,a
        end)
    end

    --The resolution of the canvas
    self.width, self.height = self.characterWidth*self.columns, self.characterHeight*self.rows

    --The canvas of the display
    self.canvas = love.graphics.newCanvas(self.width, self.height, { dpiscale=1 })
    self.canvas:setFilter("nearest")

    --The tint of the rendered display
    self.tint = {1, 1, 1, 1}

    --Wrap render call
    self.wrappedRender = function() self:render(self.memory, self.startAddress, self.attributesAddress) end
end

function display:render(memory, startAddress, attributesAddress)
    local paletteFamily = band(memory[attributesAddress], 0x70)
    for j=0, self.rows-1 do
        for i=0, self.columns-1 do
            local characterAddress = startAddress + (i+j*self.columns)*2
            local characterID = memory[characterAddress]
            local attributes = memory[characterAddress+1]
            local foreground, background = band(attributes, 0xF), rshift(attributes, 4)

            love.graphics.setColor(self.palettes[paletteFamily+background])
            love.graphics.rectangle("fill", i*self.characterWidth, j*self.characterHeight,
                self.characterWidth, self.characterHeight)
            love.graphics.setColor(self.palettes[paletteFamily+foreground])
            love.graphics.draw(self.font, self.charactersQuads[characterID], i*self.characterWidth, j*self.characterHeight)
        end
    end
end

function display:draw(x, y, w, h, memory, startAddress, attributesAddress, offsetAddress)
    self.memory, self.startAddress, self.attributesAddress = memory, startAddress, attributesAddress
    self.startAddress = math.max(self.startAddress - memory[offsetAddress]*self.columns*2, 0)

    self.canvas:renderTo(self.wrappedRender)

    local attributes = band(memory[attributesAddress], 0x7F)

    love.graphics.setColor(self.palettes[attributes])
    love.graphics.rectangle("fill", x, y, w, h)

    local scale = math.floor(math.min(w/self.width, h/self.height))

    love.graphics.setColor(self.tint)
    love.graphics.draw(self.canvas, x+(w-self.width*scale)/2, y+(h-self.height*scale)/2, 0, scale, scale)

    --Set the VSYNC bit
    attributes = attributes + 0x80
    memory[attributesAddress] = attributes
end

return display