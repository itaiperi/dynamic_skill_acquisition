local Agent = require 'Agent'

-- THIS FILE WAS NOT ACCOMODATED TO HANDLE MULTIPLE LAYERS PER TASK HEAD!

local cmd = torch.CmdLine()
cmd:option('-agent', '', 'Path to agent')
local opt = cmd:parse(arg)

local agentPath = opt.agent

local agent = torch.load(agentPath)
agent.taskHeadDepth = 1
for i = 1, agent.numTasks do
  local taskHead = agent.tasksHeads[i]
  if taskHead.weight == nil then
    error('Already fixed')
  end
  agent.tasksHeads[i] = {}
  agent.tasksHeads[i][4] = {weight=taskHead.weight, bias=taskHead.bias}
end

torch.save(agentPath, agent)
