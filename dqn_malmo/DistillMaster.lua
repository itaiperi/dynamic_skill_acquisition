local classic = require 'classic'
local signal = require 'posix.signal'
local Singleton = require 'structures/Singleton'
local Agent = require 'Agent'
local Model = require 'Model'
local nn = require 'nn'
local cunn = require "cunn"
local gnuplot = require 'gnuplot'
local Display = require 'Display'
local Validation = require 'Validation'
local ScoreKeeper = require 'ScoreKeeper'

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
  self.epochsToKeep = 30
  self.scoreKeeper = ScoreKeeper({scoresToKeep = self.epochsToKeep * self.numTasks, improvement = 1})

  -- Set up singleton global object for transferring step
  self.globals = Singleton({step = 1, distillStep = 0, studentErrors = {}, preds = {}, ys = {}, policyAccuracy = {}}) -- Initial step
  for i = 1, self.numTasks do
      self.globals.studentErrors[i], self.globals.preds[i], self.globals.ys[i], self.globals.policyAccuracy[i] = {}, {}, {}, {}
  end

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
    else
      error('Teacher ' .. self.opt.teachers[i] .. ' doesn\'t exist')
    end
  end

  -- Initialise environment
  self.mission_xmls = {
    '/home/deep1/Itai_Asaf/minecraft_lifelong_learning/missions/miner.xml',
    '/home/deep1/Itai_Asaf/minecraft_lifelong_learning/missions/hunter.xml',
  }
--  log.info('Setting up ' .. opt.env)
--  local Env = require(opt.env)
--  opt.mission_xml = self.mission_xmls[1]
--  self.env = Env(opt) -- Environment instantiation

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
      Singleton.setInstance(self.student.globals)
      self.globals = Singleton.getInstance()

    else
      self.student = Agent(opt)
    end
  else
    -- Create student network in the same form of teachers' networks, so it can be saved as an agent after training.
    self.student = Agent(opt)
  end

  -- Start gaming
  log.info('Starting ' .. opt.env)
  if opt.game ~= '' then
    log.info('Starting game: ' .. opt.game)
  end
--  local state = self.env:start()

  -- Set up display (if available)
  self.hasDisplay = false
  if opt.displaySpec then
    self.hasDisplay = true
--    self.display = Display(opt, self.env:getDisplay())
  end

  -- Set up validation (with display if available)
--  self.validation = Validation(opt, self.student, self.env, self.display)

  log.info('Starting distillation process with ' .. self.numTasks .. ' teachers')

  classic.strict(self)
end

-- Trains student
function DistillMaster:distill()
  log.info('Distilling...')

  -- Catch CTRL-C to save
--  self:catchSigInt()
  local loss = nn.MSECriterion():cuda()
--  local loss = nn.DistKLDivCriterion():cuda()

  -- Prepare student for learning, teacher for evaluating.
  self.student:training()
  for i=1, self.numTasks do
    self.teachers[i]:evaluate()
  end

  -- Training loop
  local studentErrors, preds, ys, policyAccuracy = self.globals.studentErrors, self.globals.preds, self.globals.ys, self.globals.policyAccuracy
  local epochLength = 1000
  local minEpochsForGraphs = self.epochsToKeep
  local minEpochsForEval = 200
  local valFrequency = 10 * epochLength
  local autosaveInterval = 10 * epochLength
  local lr_decay_interval = 10 * epochLength

  local lossPerTeacher = self.opt.Tensor(self.numTasks):fill(0)
  local bestEvaluationScores = self.opt.Tensor(self.numTasks):fill(-100)
  local initStep = self.globals.distillStep + 1 -- Extract step
  for step = initStep, self.opt.steps do
    self.globals.distillStep = step -- Pass step number to globals for use in other modules
    self.round = step
--  while true do
    if self.round % epochLength == 0 then
      print('Distillation step ' .. self.round .. '...')
    end
    -- Iterate over teachers every epoch, and do a mini-batch update for every teacher
    for currentTask = 1, self.numTasks do
      self.student:switchTask(currentTask)
      local teacher = self.teachers[currentTask]
      -- TODO Need to check about the validateTransition function which checks that the states sampled are not terminal,
      -- whether that's a good thing or not...
      lossPerTeacher[currentTask], pred_mean, y_mean, pred_maxQs, y_maxQs = self:distillTeacherMiniBatch(self.student, teacher, loss)
      if self.round % epochLength == 0 and self.round > epochLength * minEpochsForGraphs then
        local current_index = #studentErrors[currentTask] + 1
        studentErrors[currentTask][current_index] = lossPerTeacher[currentTask]
        preds[currentTask][current_index] = pred_mean
        ys[currentTask][current_index] = y_mean
        policyAccuracy[currentTask][current_index] = torch.eq(pred_maxQs, y_maxQs):sum() / self.batchSize
        self.scoreKeeper:addScore(policyAccuracy[currentTask][current_index])
      end
    end

    if self.round % epochLength == 0 and self.round > epochLength * minEpochsForGraphs then
      if self.round % (epochLength * 10) == 0 then
        print("Mean policy accuracy of last 5 epochs: " .. self.scoreKeeper:getMeanScore())
      end
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
    self.globals.studentErrors, self.globals.preds, self.globals.ys, self.globals.policyAccuracy = studentErrors, preds, ys, policyAccuracy
    if self.round % (autosaveInterval) == 0 then
      print('Autosaving backup of agent at distillation step ' .. self.round)
      torch.save(paths.concat(self.experiments, self._id, 'agent_autosave.t7'), self.student)
    end

--    if self.round % lr_decay_interval == 0 then
--      self.learningRate = self.learningRate / 2
--      print('Learning rate reduced to ' .. self.learningRate)
--    end

--    if self.round % valFrequency == 0 then
    if self.round % valFrequency == 0 and self.round > epochLength * minEpochsForEval then
      if self.scoreKeeper:getMeanScore() > 1.1 then
--      if self.scoreKeeper:getMeanScore() > 0.998 then
        local evaluationScores = self.opt.Tensor(self.numTasks)
        local scoresThreshold = self.opt.Tensor(self.numTasks):fill(930)
        for currentTask = 1, self.numTasks do
          self.student:switchTask(currentTask)
          self.env:changeXML(self.mission_xmls[currentTask])
          local currentEvaluation = self.opt.Tensor(self.validation:evaluate())
          for i = 1, currentEvaluation:size(1) do
            if 0 >= currentEvaluation[i] and currentEvaluation[i] >= -25 then
              currentEvaluation[i] = currentEvaluation[i] + 1000
            end
          end
          evaluationScores[currentTask] = currentEvaluation:mean()
        end


        for currentTask = 1, self.numTasks do
          print('Round ' .. self.round .. ' XML ' .. self.mission_xmls[currentTask] .. ':\nAverage Score ' ..
                  evaluationScores[currentTask] .. ', Best Score until now ' .. bestEvaluationScores[currentTask])
        end
        if evaluationScores:mean() > bestEvaluationScores:mean() - 10 then
          print('New best average distilled agent, saving!')
          bestEvaluationScores:copy(evaluationScores)
          torch.save(paths.concat(self.experiments, self._id, 'agent.t7'), self.student)
        end
--        if torch.all(evaluationScores:ge(scoresThreshold)) then
--          break
--        end
      end
    end

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
