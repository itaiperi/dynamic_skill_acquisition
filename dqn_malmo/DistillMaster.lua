local classic = require 'classic'
local signal = require 'posix.signal'
local Singleton = require 'structures/Singleton'
local Agent = require 'Agent'
local Model = require 'Model'
local nn = require 'nn'
local cunn = require "cunn"
local gnuplot = require 'gnuplot'

local DistillMaster = classic.class('DistillMaster')


-- Sets up environment and agent
function DistillMaster:_init(opt)
  self.opt = opt
  self._id = opt._id
  self.experiments = opt.experiments
  self.numTasks = opt.numTasks
  self.currentTask = 1
  self.batchSize = opt.batchSize
  self.learningRate = opt.eta
  self.distillLossThreshold = opt.distillLossThreshold
  self.round = 1

  -- Set up singleton global object for transferring step
  self.globals = Singleton({step = 1}) -- Initial step

  -- Create DQN Teachers
  torch.save(paths.concat(opt.experiments, opt._id, 'metadata.t7'), opt)
  self.teachers = {}
  print("loading " .. #self.opt.teachers .. " teachers")
  for i=1, self.numTasks do
    local path = paths.concat(opt.experiments, self.opt.teachers[i], 'agent.t7')
    print(path)
    if paths.filep(path) then
      log.info('Loading teacher ' .. i .. " from " .. path)
      self.teachers[i] = torch.load(path)
      -- change teachers' batchSize for the sake of student training (memory sampling of teachers)
      -- self.teachers[i].memory.batchSize = self.batchSize
      -- self.teachers[i].batchSize = self.batchSize
    else
      error('Teacher ' .. self.opt.teachers[i] .. ' doesn\'t exist')
    end
  end

  -- Create DQN student
  log.info('Creating Student DQN')
  local save_date = 0
  local autosave_date = 0
  local save_path = paths.concat(opt.experiments, opt._id, 'agent.t7')
  local autosave_path = paths.concat(opt.experiments, opt._id, 'agent_autosave.t7')
  if paths.filep(save_path) then
    save_date = tonumber(io.popen('stat -c %Y ' .. save_path):read())
  end
  if paths.filep(autosave_path) then
    autosave_date = tonumber(io.popen('stat -c %Y ' .. autosave_path):read())
  end
  if save_date ~= 0 or autosave_date ~= 0 then
    -- Ask to load saved agent if found in experiment folder (resuming training)
    log.info('Saved agent found - load (y/n)?')
    if io.read() == 'y' then
      -- Load the model which is more updated, among save and autosave)
      if save_date > autosave_date then
        log.info('Loading saved agent')
        self.student = torch.load(save_path)
      else
        log.info('Loading autosaved agent')
        self.student = torch.load(autosave_path)
      end
    else
      self.student = Agent(opt)
    end
  else
    -- Create student network in the same form of teachers' networks, so it can be saved as an agent after training.
    self.student = Agent(opt)
  end

  log.info('Starting distillation process with ' .. self.numTasks .. ' teachers')

  classic.strict(self)
end

-- Trains student
function DistillMaster:distill()
  log.info('Distilling...')

  -- Catch CTRL-C to save
  self:catchSigInt()
  local loss = nn.MSECriterion():cuda()
--  local loss = nn.DistKLDivCriterion():cuda()

  -- Prepare student for learning, teacher for evaluating.
  self.student:training()
  for i=1, self.numTasks do
    self.teachers[i]:evaluate()
  end

  -- Training loop
  local studentErrors, preds, ys, policyAccuracy = {}, {}, {}, {}
  local epoch_length = 1000
  local min_epochs_for_graphs = 0
  local autosave_interval = 10 * epoch_length
  local lr_decay_interval = 10 * epoch_length
  for i = 1, self.numTasks do
    studentErrors[i], preds[i], ys[i], policyAccuracy[i] = {}, {}, {}, {}
  end

  local lossPerTeacher = self.opt.Tensor(self.numTasks):fill(0)
  while true do
    if self.round % 100 == 0 then
      print('Distillation step ' .. self.round .. '...')
    end
    -- Iterate over teachers every epoch, and do a mini-batch update for every teacher
    for currentTask = 1, self.numTasks do
      self.student:switchTask(currentTask)
      local teacher = self.teachers[currentTask]
      -- TODO Need to check about the validateTransition function which checks that the states sampled are not terminal,
      -- whether that's a good thing or not...
      lossPerTeacher[currentTask], pred_mean, y_mean, pred_maxQs, y_maxQs = self:distillTeacherMiniBatch(self.student, teacher, loss)
      if self.round % epoch_length == 0 and self.round > epoch_length * min_epochs_for_graphs then
        local current_index = #studentErrors[currentTask] + 1
        studentErrors[currentTask][current_index] = lossPerTeacher[currentTask]
        preds[currentTask][current_index] = pred_mean
        ys[currentTask][current_index] = y_mean
        policyAccuracy[currentTask][current_index] = torch.eq(pred_maxQs, y_maxQs):sum() / self.batchSize
      end
      -- print('\tTeacher ' .. currentTask .. ', mini-batch MSE: ' .. lossPerTeacher[currentTask])
    end

    if self.round % epoch_length == 0 and self.round > epoch_length * min_epochs_for_graphs then
      local indices = torch.linspace(1, #studentErrors[1], #studentErrors[1])
      local multilines_error = {}
      local multilines_pred_y = {}
      local multilines_policyAccuracy = {}
      for i = 1, self.numTasks do
        multilines_error[#multilines_error + 1] = {'MSE error teacher ' .. i, indices, self.opt.Tensor(studentErrors[i])}
        multilines_pred_y[#multilines_pred_y + 1] = {'Mean prediction task ' .. i, indices, self.opt.Tensor(preds[i])}
        multilines_pred_y[#multilines_pred_y + 1] = {'Mean output teacher ' .. i, indices, self.opt.Tensor(ys[i])}
        multilines_policyAccuracy[#multilines_policyAccuracy + 1] = {'Policy accuracy task ' .. i, indices, self.opt.Tensor(policyAccuracy[i]) }
      end
      gnuplot.pngfigure(paths.concat('experiments', self._id, 'error.png'))
      gnuplot.plot(multilines_error)
      gnuplot.plotflush()
      gnuplot.pngfigure(paths.concat('experiments', self._id, 'qvalues.png'))
      gnuplot.plot(multilines_pred_y)
      gnuplot.plotflush()
      gnuplot.pngfigure(paths.concat('experiments', self._id, 'policy_accuracy.png'))
      gnuplot.plot(multilines_policyAccuracy)
      gnuplot.plotflush()

      gnuplot.closeall()
      self.student:report()
    end
    if self.round % (autosave_interval) == 0 then
      print('Autosaving backup of agent at distillation step ' .. self.round)
      torch.save(paths.concat(self.experiments, self._id, 'agent_autosave.t7'), self.student)
      -- graph_count = graph_count + 1
    end
    if lossPerTeacher:abs():le(self.distillLossThreshold):all() then
      print('MSE distances are below threshold. You can stop training now...')
      break -- TODO Should consider if we want to break, or just let the user stop with Ctrl+C.
    end

--    if self.round % lr_decay_interval == 0 then
--      self.learningRate = self.learningRate / 2
--      print('Learning rate reduced to ' .. self.learningRate)
--    end

    self.round = self.round + 1
  end
  torch.save(paths.concat(self.experiments, self._id, 'agent.t7'), self.student)
  log.info('Finished distilling')
end


function DistillMaster:distillTeacherMiniBatch(student, teacher, loss)
  local studentNet = student.policyNet
  local teacherNet = teacher.policyNet
  local studentSoftmax = nn.Sequential()
  studentSoftmax:add(nn.Identity())
  studentSoftmax:add(nn.Transpose({1, 3}))
  studentSoftmax:add(nn.SoftMax())
  studentSoftmax:add(nn.Transpose({1, 3}))
  studentSoftmax = studentSoftmax:cuda()
  local teacherSoftmax = nn.Sequential()
  teacherSoftmax:add(nn.Identity())
  teacherSoftmax:add(nn.Transpose({1, 3}))
  teacherSoftmax:add(nn.SoftMax())
  teacherSoftmax:add(nn.Transpose({1, 3}))
  teacherSoftmax = teacherSoftmax:cuda()
  studentNet:zeroGradParameters()
  local statesIndices = teacher.memory:sample()
  local states, actions, rewards, transitions, terminals = teacher.memory:retrieve(statesIndices)
  -- Pass mini-batch through teacher and student networks, calculate gradients and accumulate them
  local pred = studentNet:forward(states)
  local y = teacherNet:forward(states)
  local batchLoss = nil
  local gradOutput = nil
  if torch.type(loss) == 'nn.DistKLDivCriterion' then
    local predSoftmax = studentSoftmax:forward(pred)
    local ySoftmax = teacherSoftmax:forward(y)
    batchLoss = loss:forward(predSoftmax, ySoftmax)
    gradOutput = loss:backward(predSoftmax, ySoftmax)
    gradOutput = studentSoftmax:backward(pred, gradOutput)
    pred = predSoftmax
    y = ySoftmax
  else
    batchLoss = loss:forward(pred, y)
    gradOutput = loss:backward(pred, y)
  end
  studentNet:backward(states, gradOutput)
  -- Optimize network according to accumulated gradients
  studentNet:updateParameters(self.learningRate)
  _, pred_maxQ = torch.max(pred, 3)
  _, y_maxQ = torch.max(y, 3)
  pred_maxQ = pred_maxQ:squeeze()
  y_maxQ = y_maxQ:squeeze()
  return batchLoss, pred:mean(), y:mean(), pred_maxQ, y_maxQ
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
