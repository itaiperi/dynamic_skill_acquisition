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
cmd:option('-num_heads', 0, 'Number of heads to add to agent')
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

hiddenSize = agent.tasksHeads[1]:size(2)
num_actions = agent.tasksHeads[1]:size(1)

if hasCudnn and opt.cudnn then
  print('Creating ' .. opt.num_heads .. ' additional CUDA head weights tensors')
else
  print('Creating ' .. opt.num_heads .. ' additional non-CUDA head weights tensors')
end

for i = 1, opt.num_heads do
  newHead = nn.Linear(hiddenSize, num_actions)
  if hasCudnn and opt.cudnn then
    newHead:cuda()
  end
  newHead = newHead.weight
  agent.tasksHeads[#agent.tasksHeads + 1] = newHead
end
agent.numTasks = agent.numTasks + opt.num_heads

torch.save(agent_path_no_ext .. '_' .. agent.numTasks .. '_tasks.t7', agent)

--print(#agent.tasksHeads)
--print(agent.numTasks)
--print(agent.tasksHeads)