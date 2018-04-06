local classic = require 'classic'

local ScoreKeeper = classic.class('ScoreKeeper')

function ScoreKeeper:_init(opt)
    self.scoreQueue = {}
    self.scoresToKeep = opt.scoresToKeep
    self.improvement = opt.improvement
    self.baseScore = 0.0
    self.totalScore = 0.0
end

function ScoreKeeper:addScore(score)
    self.totalScore = self.totalScore + score
    table.insert(self.scoreQueue, 1, score)
    if #self.scoreQueue >  self.scoresToKeep then
        local oldestScore = table.remove(self.scoreQueue, #self.scoreQueue)
        self.totalScore = self.totalScore - oldestScore
    end
end

function ScoreKeeper:getMeanScore()
    if #self.scoreQueue == 0 then
        return 0.0
    end
    return self.totalScore / #self.scoreQueue
end

function ScoreKeeper:hasImproved()
    return self:getMeanScore() >= self.baseScore + self.improvement
end

function ScoreKeeper:keepScore()
    self.baseScore = self.baseScore + self.improvement
end

return ScoreKeeper
