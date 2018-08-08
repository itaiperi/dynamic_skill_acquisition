##### AGENT: d-miner-hunter-depth1.1 #####
##DISTILLATION
../run_minecraft_distill.sh 1 1 <PORT>
#validate process was 150k-300k steps

#adding 3rd head
rm experiments/d-miner-hunter-depth1-no-gs.1/agent_autosave.t7
th ./AddHeadLayers.lua -agent experiments/d-miner-hunter-depth1-no-gs.1/agent.t7
mv experiments/d-miner-hunter-depth1-no-gs.1/agent_3_tasks.t7 experiments/d-miner-hunter-depth1-no-gs.1/agent.t7

##EVALUATION OF DISTILLED AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.1 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_distill_mine.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.1 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_distill_hunt.t7

##TRAINING GS AGENT
cp -r experimnets/d-miner-hunter-depth1-no-gs.1 experiments/d-miner-hunter-depth1.1
#change steps to 2e5 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth.sh 1 1 <PORT>
#validate graphs resemble set 0

##EVALUATING GS AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth1.1 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.1/eval_scores.t7 experiments/d-miner-hunter-depth1.1/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1.1 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.1/eval_scores.t7 experiments/d-miner-hunter-depth1.1/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1.1 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_mine.t7

##TRAINING NO GS AGENT
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth-no-gs.sh 1 1 <PORT>
#validate graphs resemble set 0

##EVALUATING NO GS AGENT
#evaluating no gs agent
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.1 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.1 hunter.xml 2 <PORT>
mv experiments/d-miner-hunter-depth1-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.1 miner.xml 1 <PORT>
mv experiments/d-miner-hunter-depth1-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.1/scores_mine.t7


##### AGENT: d-miner-hunter-depth2.1 #####
##DISTILLATION
../run_minecraft_distill.sh 12 2 <PORT>
#validate process was 150k-300k steps

#adding 3rd head
rm experiments/d-miner-hunter-depth2-no-gs.1/agent_autosave.t7
th ./AddHeadLayers.lua -agent experiments/d-miner-hunter-depth2-no-gs.1/agent.t7
mv experiments/d-miner-hunter-depth2-no-gs.1/agent_3_tasks.t7 experiments/d-miner-hunter-depth2-no-gs.1/agent.t7

##EVALUATION OF DISTILLED AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.1 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.1/scores_distill_mine.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.1 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.1/scores_distill_hunt.t7

##TRAINING GS AGENT
cp -r experimnets/d-miner-hunter-depth2-no-gs.1 experiments/d-miner-hunter-depth2.1
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth.sh 1 2 <PORT>
#validate graphs resemble set 0

##EVALUATING GS AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth2.1 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.1/eval_scores.t7 experiments/d-miner-hunter-depth2.1/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2.1 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.1/eval_scores.t7 experiments/d-miner-hunter-depth2.1/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2.1 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.1/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.1/scores_mine.t7

##TRAINING NO GS AGENT
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth-no-gs.sh 1 2 <PORT>
#validate graphs resemble set 0

##EVALUATING NO GS AGENT
#evaluating no gs agent
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.1 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.14/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.14/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.14.1 hunter.xml 2 <PORT>
mv experiments/d-miner-hunter-depth2-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.1/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.1 miner.xml 1 <PORT>
mv experiments/d-miner-hunter-depth2-no-gs.1/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.1/scores_mine.t7


##### AGENT: d-miner-hunter-depth1.2 #####
##DISTILLATION
../run_minecraft_distill.sh 2 1 <PORT>
#validate process was 150k-300k steps

#adding 3rd head
rm experiments/d-miner-hunter-depth1-no-gs.2/agent_autosave.t7
th ./AddHeadLayers.lua -agent experiments/d-miner-hunter-depth1-no-gs.2/agent.t7
mv experiments/d-miner-hunter-depth1-no-gs.2/agent_3_tasks.t7 experiments/d-miner-hunter-depth1-no-gs.2/agent.t7

##EVALUATION OF DISTILLED AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.2 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_distill_mine.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.2 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_distill_hunt.t7

##TRAINING GS AGENT
cp -r experimnets/d-miner-hunter-depth1-no-gs.2 experiments/d-miner-hunter-depth1.2
#change steps to 2e5 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth.sh 2 1 <PORT>
#validate graphs resemble set 0

##EVALUATING GS AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth1.2 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.2/eval_scores.t7 experiments/d-miner-hunter-depth1.2/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1.2 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.2/eval_scores.t7 experiments/d-miner-hunter-depth1.2/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1.2 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_mine.t7

##TRAINING NO GS AGENT
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth-no-gs.sh 2 1 <PORT>
#validate graphs resemble set 0

##EVALUATING NO GS AGENT
#evaluating no gs agent
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.2 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth1-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.2 hunter.xml 2 <PORT>
mv experiments/d-miner-hunter-depth1-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth1-no-gs.2 miner.xml 1 <PORT>
mv experiments/d-miner-hunter-depth1-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth1-no-gs.2/scores_mine.t7


##### AGENT: d-miner-hunter-depth2.2 #####
##DISTILLATION
../run_minecraft_distill.sh 2 2 <PORT>
#validate process was 150k-300k steps

#adding 3rd head
rm experiments/d-miner-hunter-depth2-no-gs.2/agent_autosave.t7
th ./AddHeadLayers.lua -agent experiments/d-miner-hunter-depth2-no-gs.2/agent.t7
mv experiments/d-miner-hunter-depth2-no-gs.2/agent_3_tasks.t7 experiments/d-miner-hunter-depth2-no-gs.2/agent.t7

##EVALUATION OF DISTILLED AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.2 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_distill_mine.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.2 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_distill_hunt.t7

##TRAINING GS AGENT
cp -r experimnets/d-miner-hunter-depth2-no-gs.2 experiments/d-miner-hunter-depth2.2
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth.sh 2 2 <PORT>
#validate graphs resemble set 0

##EVALUATING GS AGENT
./evalScripts/evalScript.sh d-miner-hunter-depth2.2 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.2/eval_scores.t7 experiments/d-miner-hunter-depth2.2/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2.2 hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.2/eval_scores.t7 experiments/d-miner-hunter-depth2.2/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2.2 miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_mine.t7

##TRAINING NO GS AGENT
#change steps to 15e4 in trainAgent.sh
run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth-no-gs.sh 2 2 <PORT>
#validate graphs resemble set 0

##EVALUATING NO GS AGENT
#evaluating no gs agent
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.2 cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/d-miner-hunter-depth2-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_cooker.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.2 hunter.xml 2 <PORT>
mv experiments/d-miner-hunter-depth2-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_hunt.t7
./evalScripts/evalScript.sh d-miner-hunter-depth2-no-gs.2 miner.xml 1 <PORT>
mv experiments/d-miner-hunter-depth2-no-gs.2/eval_scores.t7 experiments/d-miner-hunter-depth2-no-gs.2/scores_mine.t7
