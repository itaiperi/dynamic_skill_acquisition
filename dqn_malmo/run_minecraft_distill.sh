#!/bin/bash

# $1 - sid
# $2 - depth
# $3 - port

th $DQNF/distill_main.lua -env DiscreteMinecraft -modelBody models.Minecraft -mode train -height 84 -width 84 -zoom 4 -valSteps 30 -hiddenSize 256 -histLen 4 -bootstraps 0 -memSampleFreq 400 -memNSamples 100 -memSize 5e4 -learnStart 5e3 -epsilonSteps 75e3 -tau 1000 -rewardClip 0 -tdClip 0 -gradClip 0 -verbose true -progFreq 1e3 -reportWeights true -cudnn true -x_min_limit -3 -x_max_limit 3 -z_min_limit -3 -z_max_limit 3 -steps 2e5 -mission_xml /home/deep1/Itai_Asaf/minecraft_lifelong_learning/missions/hunter.xml -findReward 1000 -commandReward -1 -timeReward 0 -roundTime 4000 -actionsNum 4 -randomStart true -gamma 0.97 -valFreq 3e4 -batchSize 32 -teachers miner.$1,hunter.$1 -_id d-miner-hunter-depth$2.$1 -eta 3e-6 -duel false -taskHeadDepth $2 -port $3
