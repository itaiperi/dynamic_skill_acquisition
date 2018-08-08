local classic = require 'classic'
local cunn = require 'cunn'
local Agent = require 'Agent'

local hasCudnn, cudnn = pcall(require, 'cudnn') -- Use cuDNN if available

-- Taken from https://stackoverflow.com/questions/1426954/split-string-in-lua
function split(inputstr, sep)
  if sep == nil then
          sep = "%s"
  end
  local t = {}
  local i = 1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
          t[i] = str
          i = i + 1
  end
  return t
end

local function abortIf(err, msg)
  if err then
    log.error(msg)
    error(msg)
  end
end

local cmd = torch.CmdLine()
cmd:option('-agent', '', 'Agent to add head layers to')
cmd:option('-numHeads', 1, 'Number of heads to add to agent')
cmd:option('-cudnn', 'true', 'Whether to use cudnn or not')
local opt = cmd:parse(arg)
opt.cudnn = opt.cudnn == 'true'

local agent_path = opt.agent
local agent_path_no_ext = agent_path:sub(1, agent_path:len()-3)
abortIf(not paths.filep(agent_path), 'No agent exists in the folder!')
agent = torch.load(agent_path)

--print(agent.policyNet)
--print(#agent.tasksHeads)
--print(agent.numTasks)

--hiddenSize = agent.tasksHeads[1].weight:size(2)
--num_actions = agent.tasksHeads[1].weight:size(1)

if hasCudnn and opt.cudnn then
  print('Creating ' .. opt.numHeads .. ' additional CUDA head weights tensors')
else
  print('Creating ' .. opt.numHeads .. ' additional non-CUDA head weights tensors')
end

local trainableLayers = agent:trainableLayers()

for i = 1 + #agent.tasksHeads, opt.numHeads + #agent.tasksHeads do
  agent.tasksHeads[i] = {}
  for j, _ in pairs(agent.tasksHeads[1]) do
    local newHead = nil
    local layer = trainableLayers[j].layer
    if trainableLayers[j].layerType == 'nn.Linear' then
      local inputSize = layer.weight:size(2)
      local outputSize = layer.weight:size(1)
      newHead = nn.Linear(inputSize, outputSize)
    elseif trainableLayers[j].layerType == 'nn.SpatialConvolution' or trainableLayers[j].layerType == 'cudnn.SpatialConvolution' then
      newHead = nn.SpatialConvolution(layer.nInputPlane, layer.nOutputPlane, layer.kW, layer.kH, layer.dW,
        layer.dH, layer.padW, layer.padH)
    end
    if hasCudnn and opt.cudnn then
      newHead:cuda()
    end
    agent.tasksHeads[i][j] = {weight = newHead.weight:clone(), bias = newHead.bias:clone()}
  end
end
--  local newHead = nn.Linear(hiddenSize, num_actions)
--  if hasCudnn and opt.cudnn then
--    newHead:cuda()
--  end
--  agent.tasksHeads[#agent.tasksHeads + 1] = {weight = newHead.weight, bias = newHead.bias}
--  agent.tasksHeads[#agent.tasksHeads + 1] = {weight = (agent.tasksHeads[2].weight:clone() + agent.tasksHeads[1].weight:clone()) / 2,
--    bias = (agent.tasksHeads[2].bias:clone() + agent.tasksHeads[1].bias:clone()) / 2}
--end
agent.numTasks = agent.numTasks + opt.numHeads

torch.save(agent_path_no_ext .. '_' .. agent.numTasks .. '_tasks.t7', agent)

--print(#agent.tasksHeads)
--print(agent.numTasks)
--print(agent.tasksHeads)