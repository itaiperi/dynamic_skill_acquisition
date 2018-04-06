#!/bin/bash

# $1 = id
# $2 = mission xml name (including .xml)
# $3 = actions number
# $4 = port
# $5 = task number to train
# $6 = number of layers to freeze
# $7 = eta
# $8 = lrDecay
# $9 = etaFinal

th main.lua -env DiscreteMinecraft -modelBody models.Minecraft -mode train -height 84 -width 84 -zoom 4 -hiddenSize 256 -histLen 4 -bootstraps 0 -memSampleFreq 400 -memNSamples 100 -memSize 5e4 -learnStart 5e3 -epsilonSteps 5e4 -tau 1000 -rewardClip 0 -tdClip 0 -gradClip 0 -verbose true -progFreq 1e3 -reportWeights true -cudnn true -x_min_limit -3 -x_max_limit 2 -z_min_limit -2 -z_max_limit 3 -steps 5e8 -duel false -recurrent false  -findReward 1000 -commandReward -1 -timeReward 0 -roundTime 6000 -gamma 0.97 -valFreq 5e3  -valSteps 600 -randomStart true -_id $1 -mission_xml /home/deep1/Itai_Asaf/minecraft_lifelong_learning/missions/$2 -port $4 -actionsNum $3 -task $5 -freezeLayers $6 -eta $7 -lrDecay $8 -etaFinal $9
