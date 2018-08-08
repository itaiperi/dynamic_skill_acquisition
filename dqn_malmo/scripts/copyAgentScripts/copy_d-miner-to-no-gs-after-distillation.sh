#!/bin/bash

# $1 - sid
# $2 - depth

rm -r experiments/d-miner-hunter-depth$2-no-gs.$1
th ./AddHeadLayers.lua -agent experiments/d-miner-hunter-depth$2.$1/agent.t7
mv experiments/d-miner-hunter-depth$2.$1/agent_3_tasks.t7 experiments/d-miner-hunter-depth$2.$1/agent.t7
cp -r experiments/d-miner-hunter-depth$2.$1 experiments/d-miner-hunter$2-no-gs.$1
