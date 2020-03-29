local libraryPath = string.sub((...), 1, -1-string.len(".speaker"))

local bit = require("bit")
local lshift = bit.lshift

--Require the object-oriented library
local class = require(libraryPath..".middleclass")

local speaker = class("charcoal.Speaker")

function speaker:initialize()
    self.sampleRate = 44100
    self.bitDepth = 8
    self.buffercount = 5
    self.preferredLength = self.sampleRate/40

    self.queueableSource = love.audio.newQueueableSource(self.sampleRate, self.bitDepth, 1, self.buffercount)
    self.queueableSource:setVolume(0.25)

    self.buffer = {}
    self.nextPieceID = 0
    self.piecesToGenerate = self.buffercount
    self.samplesForHalfwave = 0
    self.waveform = 0
end

function speaker:generateSoundData(waveform, samplesForHalfwave)
    local cycles = math.ceil(self.preferredLength/(samplesForHalfwave*2))
    local soundData = love.sound.newSoundData(cycles*samplesForHalfwave*2, self.sampleRate, self.bitDepth, 1)

    for c=0, cycles-1 do
        for i=0, samplesForHalfwave*2-1 do
            if waveform == 0 then --Square
                soundData:setSample(i+c*samplesForHalfwave*2, 1,
                    (i < samplesForHalfwave) and 1 or -1)

            elseif waveform == 1 then --Sawtooth
                soundData:setSample(i+c*samplesForHalfwave*2, 1,
                    (i-samplesForHalfwave)/samplesForHalfwave)

            elseif waveform == 2 then --Triangle
                local period = i/(samplesForHalfwave*2)
                period = period < 0.75 and period+0.25 or period-0.75
                soundData:setSample(i+c*samplesForHalfwave*2, 1,
                    period < 0.5 and period*4-1 or 1-(period-0.5)*4)

            elseif waveform == 3 then --Sine
                soundData:setSample(i+c*samplesForHalfwave*2, 1,
                    math.sin((i/samplesForHalfwave)*math.pi))
            end
        end
    end

    return soundData
end

function speaker:update(dt, waveform, samplesForHalfwave)
    if waveform ~= self.waveform or self.samplesForHalfwave ~= samplesForHalfwave then
        self.waveform, self.samplesForHalfwave = waveform, samplesForHalfwave
        self.piecesToGenerate = self.buffercount
        
        self.queueableSource:stop()
    end

    if self.samplesForHalfwave == 0 then return end

    for i=0, self.queueableSource:getFreeBufferCount() do
        local soundData = self.buffer[self.nextPieceID]

        --Regenerate the piece
        if self.piecesToGenerate > 0 then
            if soundData then soundData:release() end
            soundData = self:generateSoundData(waveform, samplesForHalfwave)
            self.buffer[self.nextPieceID] = soundData
            self.piecesToGenerate = self.piecesToGenerate-1
        end

        self.queueableSource:queue(soundData)
        self.nextPieceID = (self.nextPieceID + 1) % self.buffercount
    end

    if not self.queueableSource:isPlaying() then
        self.queueableSource:play()
    end
end

return speaker