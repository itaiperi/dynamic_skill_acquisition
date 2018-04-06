#!/bin/bash

# $1 = id
# $2 = mission xml name (including .xml)
# $3 = task number to train
# $4 = port

th $DQNF/main.lua -env DiscreteMinecraft -modelBody models.Minecraft -mode eval -height 84 -width 84 -zoom 4 -valSteps 200 -hiddenSize 256 -duel false -histLen 4 -bootstraps 0 -memSampleFreq 400 -memNSamples 100 -memSize 5e4 -learnStart 5e3 -epsilonSteps 5e4 -eta 0.01 -tau 1000 -rewardClip 0 -tdClip 0 -gradClip 0 -verbose true -progFreq 1e3 -reportWeights true -cudnn true -_id $1 -x_min_limit -3 -x_max_limit 3 -z_min_limit -3 -z_max_limit 3 -randomStart true -steps 5e8 -mission_xml /home/deep1/Itai_Asaf/minecraft_lifelong_learning/missions/$2 -findReward 1000 -commandReward -1 -timeReward 0 -roundTime 6000 -port $4 -gamma 0.99 -valFreq 3e4 -batchSize 32 -task $3
