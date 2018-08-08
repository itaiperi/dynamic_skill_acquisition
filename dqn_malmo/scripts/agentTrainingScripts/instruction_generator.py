

change_gs_steps = "#change steps to 15e4 in trainAgent.sh"
change_1_gs_steps = "#change steps to 2e5 in trainAgent.sh"
code = """##### AGENT: <GS_AGENT_NAME> #####
##DISTILLATION
./run_minecraft_distill.sh <SID> <DEPTH> <PORT>
#validate process was 150k-300k steps

#adding 3rd head
rm experiments/<AGENT_NAME>/agent_autosave.t7
th ./AddHeadLayer.lua -agent experiments/<AGENT_NAME>/agent.t7
mv experiments/<AGENT_NAME>/agent_3_layers.t7 experiments/<AGENT_NAME>/agent.t7

##EVALUATION OF DISTILLED AGENT
./evalScripts/evalScript.sh <AGENT_NAME> miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/<AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_distill_mine.t7
./evalScripts/evalScript.sh <AGENT_NAME> hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/<AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_distill_hunt.t7

##TRAINING GS AGENT 
cp -r experimnets/<AGENT_NAME> experiments/<GS_AGENT_NAME>
<CHANGE_GS_STEPS>
./run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth.sh <SID> <DEPTH> <PORT>
#validate graphs resemble set 0

##EVALUATING GS AGENT
./evalScripts/evalScript.sh <GS_AGENT_NAME> cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/<GS_AGENT_NAME>/eval_scores.t7 experiments/<GS_AGENT_NAME>/scores_cooker.t7
./evalScripts/evalScript.sh <GS_AGENT_NAME> hunter.xml 2 <PORT>
#validate mean is > 960
mv experiments/<GS_AGENT_NAME>/eval_scores.t7 experiments/<GS_AGENT_NAME>/scores_hunt.t7
./evalScripts/evalScript.sh <GS_AGENT_NAME> miner.xml 1 <PORT>
#validate mean is > 960
mv experiments/<GS_AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_mine.t7

##TRAINING NO GS AGENT 
#change steps to 15e4 in trainAgent.sh
./run_scripts_cont.sh ./agentTrainingScripts/train-d-cooker-depth-no-gs.sh <SID> <DEPTH> <PORT>
#validate graphs resemble set 0

##EVALUATING NO GS AGENT
#evaluating no gs agent
./evalScripts/evalScript.sh <AGENT_NAME> cooker.xml 3 <PORT>
#validate mean is > 960
mv experiments/<AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_cooker.t7
./evalScripts/evalScript.sh <AGENT_NAME> hunter.xml 2 <PORT>
mv experiments/<AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_hunt.t7
./evalScripts/evalScript.sh <AGENT_NAME> miner.xml 1 <PORT>
mv experiments/<AGENT_NAME>/eval_scores.t7 experiments/<AGENT_NAME>/scores_mine.t7

"""

if __name__ == '__main__':
    for sid in (1, 2):
        for depth in (1, 2):
            agent_name = "d-miner-hunter-depth" + str(depth) + "-no-gs." + str(sid)
            gs_agent_name = "d-miner-hunter-depth" + str(depth) + "." + str(sid)
            change = change_gs_steps
            if depth is 1:
                change = change_1_gs_steps
            print(code.replace("<SID>", str(sid)).replace("<DEPTH>", str(depth)).replace("<CHANGE_GS_STEPS>", change).replace("<AGENT_NAME>", agent_name).replace("<GS_AGENT_NAME>", gs_agent_name))