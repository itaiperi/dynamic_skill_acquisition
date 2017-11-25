local Setup = require 'Setup'
local DistillMaster = require 'DistillMaster'

-- Parse options and perform setup
local setup = Setup(arg)
local opt = setup.opt

-- Start master experiment runner
local master = DistillMaster(opt)

if opt.mode == 'train' then
  master:distill()
end
