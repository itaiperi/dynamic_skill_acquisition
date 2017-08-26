local classic = require 'classic'
local signal = require 'posix.signal'
local Singleton = require 'structures/Singleton'
local Agent = require 'Agent'
local Model = require 'Model'

local DistillMaster = classic.class('DistillMaster')


-- Sets up environment and agent
function DistillMaster:_init(opt)
  self.opt = opt
  self.experiments = opt.experiments
  self.numTasks = 1 -- opt.numTasks
  self.currentTask = 1
  self.batchSize = 32
  self.learningRate = opt.eta
  self.distillLossThreshold = opt.distillLossThreshold

  -- Set up singleton global object for transferring step
  self.globals = Singleton({step = 1}) -- Initial step

  -- Create DQN Teachers
  self.teachers = {}
  for i=1, self.numTasks do
    if paths.filep(paths.concat(opt.experiments, 'teacher_' .. i, 'agent.t7')) then
      log.info('Loading teacher ' .. i)
      self.teachers[i] = torch.load(paths.concat(opt.experiments, 'teacher_' .. i, 'agent.t7'))
      -- change teachers' batchSize for the sake of student training (memory sampling of teachers)
      self.teachers[i].memory.batchSize = self.batchSize
    else
      error('Teacher ' .. i .. ' doesn\'t exist')
    end
  end

  -- Create DQN student
  log.info('Creating Student DQN')
  -- Create student network in the same form of teachers' networks, so it can be saved as an agent after training.
  self.student = Agent(opt)

  log.info('Starting distillation process with ' .. self.numTasks .. ' teachers')

  classic.strict(self)
end

-- Trains student
function DistillMaster:distill()
  log.info('Distilling...')

  -- Catch CTRL-C to save
  self:catchSigInt()

  -- Prepare student for learning, teacher for evaluating.
  self.student.policyNet:training()
  for i=1, self.numTasks do
    self.teachers[i].policyNet:evaluate()
  end

  -- Training loop
  local loss = nn.DistKLDivCriterion()
  local epoch = 1
  while True do
    print('Epoch ' .. epoch '...')
    -- Iterate over teachers every epoch, and do a mini-batch update for every teacher
    local lossPerTeacher = opt.Tensor(self.numTasks):fill(0)
    for currentTask = 1, self.numTasks do
      self.student:switchTask(currentTask)
      local teacher = self.teachers[currentTask]
      -- TODO Need to check about the validateTransition function which checks that the states sampled are not terminal,
      -- whether that's a good thing or not...
      lossPerTeacher[currentTask] = self.distillTeacherMiniBatch(self.student, teacher, loss)
      print('\tTeacher ' .. currentTask .. ', mini-batch KL error: ' .. lossPerTeacher[currentTask])
    end
    if lossPerTeacher:le(self.distillLossThreshold):all() then
      print('KL distances are below threshold. You can stop training now...')
      break -- TODO Should consider if we want to break, or just let the user stop with Ctrl+C.
    end
     epoch = epoch + 1
  end
  log.info('Finished distilling')
end


function DistillMaster:distillTeacherMiniBatch(student, teacher, loss)
  student.policyNet:zeroGradParameters()
  local statesIndices = teacher.memory:sample()
  local states = teacher.memory:retrieve(statesIndices)
  -- Pass mini-batch through teacher and student networks, calculate gradients and accumulate them
  local pred = student.policyNet:forward(states)
  local y = teacher.policyNet:forward(states)
  local batchLoss = loss:forward(pred, y)
  local gradOutput = loss:backward(pred, y)
  student.policyNet:backward(pred, gradOutput)
  -- Optimize network according to accumulated gradients
  student.policyNet:updateParameters(self.learningRate)
  return batchLoss
end


-- Sets up SIGINT (Ctrl+C) handler to save network before quitting
function DistillMaster:catchSigInt()
  signal.signal(signal.SIGINT, function(signum)
    log.warn('SIGINT received')
    log.info('Save student (y/n)?')
    if io.read() == 'y' then
      log.info('Saving student')
      torch.save(paths.concat(self.experiments, self._id, 'agent.t7'), self.student) -- Save student to resume training
    end
    log.warn('Exiting')
    os.exit(128 + signum)
  end)
end

return DistillMaster
