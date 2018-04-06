#!/bin/bash

# $1 = set number (0,1,2)
# $2 = port

distilled_agents=("d-miner-hunter-depth1" "d-miner-hunter-depth1-no-gs" "d-miner-hunter-depth2" "d-miner-hunter-depth2-no-gs")
baseline_agents=("miner" "hunter" "cooker")

for agent in ${baseline_agents[@]}; do
    echo Running agent $agent.$1
    printf 'y\ny\n' | ./evalScripts/evalScript.sh $agent.$1 $agent.xml 1 $2
done

for agent in ${distilled_agents[@]}; do
    echo Running agent $agent.$1
    ./evalScripts/eval_distilled_all_tasks.sh $agent.$1 $2
done
