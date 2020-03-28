local libraryPath = string.sub((...), 1, -1-string.len(".processor"))

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

--The processor class

local Processor = class("charcoal.Processor")

--== Constant Variables ==--

local bit = require("bit")
local band, bor, bxor, lshift, rshift = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift

--The instructions types
local instructionsSet = {
    --[1]: No operands instructions
    {"RET", "NOP", "HALT"},

    --[2]: 1 operand instructions
    {"NOT", "PUSH", "POP", "CALL", "JMP", "JG", "JNG", "JL", "JNL", "JE", "JNE", "EXTI"},

    --[3]: 2 operands instructions
    {"ADD", "SUB", "MUL", "DIV", "MOD", "SWIZ", "AND", "OR", "XOR", "SHL", "SHR", "SAR", "SET", "GET", "CMP"},

    --[4]: Special instructions
    {"EXTA", "EXTB"}
}

for itype, instructions in ipairs(instructionsSet) do
    for _, instruction in ipairs(instructions) do
        instructionsSet[instruction] = itype
    end
end

--The instructions encoded id
local instructionsNumeration = {
    "HALT", "NOP", --Miscellaneuous
    "ADD", "SUB", "MUL", "DIV", "MOD", "SWIZ", --Arithmetic
    "NOT", "AND", "OR", "XOR", "SHL", "SHR", "SAR", --Bitwise
    "SET", "GET", "PUSH", "POP", "CALL", "RET", --Transfare
    "JMP", "CMP", "JG", "JNG", "JL", "JNL", "JE", "JNE", --Control
    "EXTI", "EXTA", "EXTB" --Extension
}

local instructionsBehaviour = {
    function(self) -- 0 HALT
        self.halt = true
    end,

    function() -- 1 NOP
        --NO OPERATION
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 2 ADD
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = math.min(self.registers[operand1] + value, 0xFFFF)
        else
            self:setShort(operand1, math.min(self:getShort(operand1) + value, 0xFFFF))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 3 SUB
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = math.max(self.registers[operand1] - value, 0)
        else
            self:setShort(operand1, math.max(self:getShort(operand1) - value, 0))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 4 MUL
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = math.min(self.registers[operand1] * value, 0xFFFF)
        else
            self:setShort(operand1, math.min(self:getShort(operand1) * value, 0xFFFF))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 5 DIV
        local value = isRegister2 and self.registers[operand2] or operand2
        if value == 0 then self.halt = true return end --Abort instruction execution

        if isRegister1 then
            self.registers[operand1] = math.floor(self.registers[operand1] / value)
        else
            self:setShort(operand1, math.floor(self:getShort(operand1) / value))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 6 MOD
        local value = isRegister2 and self.registers[operand2] or operand2
        if value == 0 then self.halt = true return end --Abort instruction execution

        if isRegister1 then
            self.registers[operand1] = self.registers[operand1] % value
        else
            self:setShort(operand1, self:getShort(operand1) % value)
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 7 SWIZ
        local mask = isRegister2 and self.registers[operand2] or operand2
        local value = isRegister1 and self.registers[operand1] or self:getShort(operand1)

        local digits = {0,0,0,0,0}
        for i=1, 5 do
            digits[i] = value % 10
            value = math.floor(value / 10)
        end

        for i=0, 4 do
            value = value + (digits[mask % 10] or 0) * (10 ^ i)
            mask = math.floor(mask / 10)
        end

        if isRegister1 then self.registers[operand1] = value
        else self:setShort(operand1, value) end
    end,

    function(self, isRegister1, operand1) -- 8 NOT
        if isRegister1 then
            self.registers[operand1] = bxor(0xFFFF, self.registers[operand1])
        else
            self:setShort(operand1, bxor(0xFFFF, self:getShort(operand1)))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 9 OR
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = bor(self.registers[operand1], value)
        else
            self:setShort(operand1, band(self:getShort(operand1), value))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- 9 OR
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = bor(self.registers[operand1], value)
        else
            self:setShort(operand1, bor(self:getShort(operand1), value))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- XOR
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = bxor(self.registers[operand1], value)
        else
            self:setShort(operand1, bxor(self:getShort(operand1), value))
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- SHL
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = band(lshift(self.registers[operand1], value), 0xFFFF)
        else
            self:setShort(operand1, band(lshift(self:getShort(operand1), value)), 0xFFFF)
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- SHR
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = rshift(self.registers[operand1], value)
        else
            self:setShort(operand1, rshift(self:getShort(operand1), value))
        end
    end,

    --TODO: Test the arithmetic shift if it works correctly
    function(self, isRegister1, operand1, isRegister2, operand2) -- SAR
        local bits = isRegister2 and self.registers[operand2] or operand2
        local value = isRegister1 and self.registers[operand1] or self:getShort(operand1)

        if value >= 0x8000 then
            value = band(0xFFFF, rshift(value, bits))
        else
            value = rshift(value, bits)
        end

        if isRegister1 then self.registers[operand1] = value
        else self:setShort(operand1, value) end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- SET
        local value = isRegister2 and self.registers[operand2] or operand2

        if isRegister1 then
            self.registers[operand1] = value
        else
            self:setShort(operand1, value)
        end
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- GET
        local value = isRegister1 and self:getShort(self.registers[operand1]) or self:getShort(operand1)

        if isRegister2 then
            self.registers[operand2] = value
        else
            self:setShort(operand2, value)
        end
    end,

    function(self, isRegister1, operand1) -- PUSH
        self:setShort(self.registers[5], isRegister1 and self.registers[operand1] or operand1)
        self.registers[5] = math.min(self.registers[5]+2, 0xFFFF)
    end,

    function(self, isRegister1, operand1) -- POP
        self.registers[5] = math.max(self.registers[5]-2, 0)

        if isRegister1 then
            self.registers[operand1] = self:getShort(self.registers[5])
        else
            self:setShort(operand1, self:getShort(self.registers[5]))
        end
    end,

    function(self, isRegister1, operand1, _, _, byteCount) -- CALL
        self:setShort(self.registers[5], math.min(self.registers[6]+byteCount, 0xFFFF))
        self.registers[5] = math.min(self.registers[5]+2, 0xFFFF)
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self) -- RET
        self.registers[5] = math.max(self.registers[5]-2, 0)
        self.registers[6] = self:getShort(self.registers[5])
        return true
    end,

    function(self, isRegister1, operand1) -- JMP
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- CMP
        local value1 = isRegister1 and self.registers[operand1] or self:getShort(operand1)
        local value2 = isRegister2 and self.registers[operand2] or operand2

        local comp = math.max(math.min(value2 - value1, 0x7FFF), -0x8000)
        if comp < 0 then comp = 0xFFFF - comp end

        self.registers[4] = comp
    end,

    function(self, isRegister1, operand1) -- JG
        if self.registers[4] > 0x7FFF or self.registers[4] == 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1) -- JNG
        if self.registers[4] <= 0x7FFF and self.registers[4] ~= 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1) -- JL
        if self.registers[4] <= 0x7FFF or self.registers[4] == 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1) -- JNL
        if self.registers[4] > 0x7FFF and self.registers[4] ~= 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1) -- JE
        if self.registers[4] ~= 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1) -- JNE
        if self.registers[4] ~= 0 then return end
        self.registers[6] = isRegister1 and self.registers[operand1] or operand1
        return true
    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- EXTI

    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- EXTA

    end,

    function(self, isRegister1, operand1, isRegister2, operand2) -- EXTB

    end
}

--== Methods ==--

function Processor:initialize()
    --The machine state
    self.registers = { [0] = 0; 0, 0, 0, 0, 0, 0, 0 } --8 Registers
    self.memory = {} --The 64KB memory
    for i=0, 0xFFFF do self.memory[i] = 0 end -- Fill the memory with 0s
    self.halt = false --Is the processor in the HALT state
end

--Load a binary image of the memory from a file, doesn't close the file
function Processor:loadImage(file)
    local function nextByte()
        local char = file:read(1)
        return char and string.byte(char)
    end

    local address = 0

    for byte in nextByte do
        self.memory[address] = byte
        address = address + 1

        if address > 0xFFFF then break end
    end
end

--Get the memory array of the processor
function Processor:getMemory()
    return self.memory
end

--Get a short integer from memory
function Processor:getShort(address)
    return self.memory[address] + lshift(self.memory[math.min(address+1, 0xFFFF)], 8)
end

--Set a short integer in memory
function Processor:setShort(address, value)
    self.memory[address], self.memory[math.min(address+1, 0xFFFF)] = band(value, 0xFF), rshift(value, 8)
end

--Execute a processor cycle
function Processor:executeCycle()
    if self.halt then return end

    local nextByteAddress = self.registers[6] -- THe program pointer register (PP)
    local bytesRead = 0
    local function nextByte()
        --TODO: document the memory end collision behaviour

        local byte = self.memory[nextByteAddress]
        bytesRead = bytesRead + 1
        nextByteAddress = math.min(nextByteAddress+1, 0xFFFF)

        return byte
    end

    local instructionByte = nextByte()
    local instructionID = band(instructionByte, 0x1F)
    local instructionName = instructionsNumeration[instructionID+1]
    local instructionType = instructionsSet[instructionName]

    local operand1Type = band(rshift(instructionByte, 5), 0x3)
    local operand2Type = rshift(instructionByte, 7)

    local isRegister1, isRegister2 = (operand1Type == 0), (operand2Type == 0)
    local operand1, operand2 = 0, 0

    if instructionType == 3 and isRegister1 and isRegister2 then
        local registersByte = nextByte()
        operand1 = band(registersByte, 7)
        operand2 = band(rshift(registersByte, 4), 7)
    elseif instructionType ~= 4 then
        if instructionType == 2 or instructionType == 3 then
            if isRegister1 then --Register
                operand1 = band(nextByte(), 7)
            elseif operand1Type == 1 then --Literal Value
                operand1 = nextByte() + lshift(nextByte(), 8)
            else --Memory reference
                local referenceByte = nextByte()
                local register = band(referenceByte, 7)
                local offset = rshift(referenceByte, 3)
                if offset > 15 then offset = -(32-offset) end

                operand1 = math.max(math.min(self.registers[register]+offset, 0xFFFF), 0)
            end
        end

        if instructionType == 3 then
            if isRegister2 then --Register
                operand2 = band(nextByte(), 7)
            else --Literal Value
                operand2 = nextByte() + lshift(nextByte(), 8)
            end
        end
    end

    local skipPointerUpdate = instructionsBehaviour[instructionID+1](self, isRegister1, operand1, isRegister2, operand2, bytesRead)
    if not skipPointerUpdate then
        self.registers[6] = math.min(self.registers[6] + bytesRead, 0xFFFF) --Increase PP by the amount of bytes read
    end

    self.registers[7] = math.min(self.registers[7] + 1, 0xFFFF) -- increase the clock value by 1 -- last thing after execution of instruction
end

return Processor