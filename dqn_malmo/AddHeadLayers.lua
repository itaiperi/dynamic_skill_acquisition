local classic = require 'classic'
local cunn = require 'cunn'
local Agent = require 'Agent'

local hasCudnn, cudnn = pcall(require, 'cudnn') -- Use cuDNN if available

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

abortIf(not paths.filep(opt.agent), 'No agent exists in the folder!')
agent = torch.load(opt.agent)
print(agent)
--print(agent.policyNet)
print(#agent.tasksHeads)
print(agent.numTasks)

hiddenSize = agent.tasksHeads[1]:size(2)
num_actions = agent.tasksHeads[1]:size(1)

for i = 1, opt.num_heads do
  newHead = nn.Linear(hiddenSize, num_actions)
  if hasCudnn and opt.cudnn then
    newHead:cuda()
  end
  newHead = newHead.weight
  agent.tasksHeads[#agent.tasksHeads + 1] = newHead
end
agent.numTasks = agent.numTasks + opt.num_heads

torch.save(opt.agent .. '.heads.t7', agent)
--print(#agent.tasksHeads)
--print(agent.tasksHeads)