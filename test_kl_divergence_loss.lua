local nn = require "nn"
local cunn = require "cunn"

local net = nn.Sequential()
net:add(nn.View(histLen*self.stateSpec[2][1], self.stateSpec[2][2], self.stateSpec[2][3])) -- Concatenate history in channel dimension
net:add(nn.SpatialConvolution(histLen*self.stateSpec[2][1], 16, 4, 4, 2, 2, 1, 1))
net:add(nn.SpatialMaxPooling(2, 2))
net:add(nn.ReLU(true))
net:add(nn.SpatialConvolution(16, 32, 3, 3, 2, 2))
net:add(nn.SpatialMaxPooling(2, 2))
net:add(nn.ReLU(true))
