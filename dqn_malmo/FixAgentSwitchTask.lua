local Agent = require 'Agent'

-- THIS FILE WAS NOT ACCOMODATED TO HANDLE MULTIPLE LAYERS PER TASK HEAD!

local cmd = torch.CmdLine()
cmd:option('-agent', '', 'Path to agent')
local opt = cmd:parse(arg)

local agent_path = opt.agent

local agent = torch.load(agent_path)
if agent.numTasks > 1 then
    error('Do not do this for distilled / multi-task agents!')
end
local headLayer = agent.policyNet:findModules('nn.Linear')[2]
agent.tasksHeads[1] = {weight=headLayer.weight:clone(), bias=headLayer.bias:clone()}

print('Original and copied weights are the same: ' .. tostring(torch.all(agent.tasksHeads[1].weight:eq(headLayer.weight))))
print('Original and copied biases are the same: ' .. tostring(torch.all(agent.tasksHeads[1].bias:eq(headLayer.bias))))

torch.save(agent_path, agent)
saved_agent = torch.load(agent_path)

if torch.all(saved_agent.tasksHeads[1].weight:eq(headLayer.weight)) and torch.all(saved_agent.tasksHeads[1].bias:eq(headLayer.bias)) then
    print('SUCCESS! Loaded agent has same weights and biases!')
else
    print('SOMETHING WENT WRONG! weights and/or biases of loaded agent are incorrect!')
end