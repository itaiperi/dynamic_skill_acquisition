#!/bin/bash

# $1 - serial num
# $2 - depth
# $3 - port

layers_to_freeze=$((4-$2))
echo $layers_to_freeze





agentTrainingScripts/trainAgent.sh d-miner-hunter-depth$2.$1 miner.xml 4 $3 1 $layers_to_freeze 0.00025