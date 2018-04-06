import os
import subprocess
import signal
import time

prefix = 'd-miner-hunter-depth'
# agents_ids_gs = [prefix + depth + '.' + id for depth in range(1, 3) for id in range(3)]
# agents_ids_no_gs = [prefix + depth + '-no-gs.' + id for depth in range(1, 3) for id in range(3)]

port = 10000
# port = 20000
env = '/home/deep1/Itai_Asaf/minecraft_lifelong_learning/malmo/Minecraft/launchClient.sh'
dqn_malmo = '/home/deep1/Itai_Asaf/minecraft_lifelong_learning/dqn_malmo'
experiments = os.path.join(dqn_malmo, 'experiments')
train_script = os.path.join(dqn_malmo, 'agentTrainingScripts/train-d-cooker-depth.sh')
# train_script = os.path.join(dqn_malmo, 'agentTrainingScripts/train-d-cooker-depth-no-gs.sh')
for depth in range(1, 2):
# for depth in range(1, 3):
#     for serial in range(3):
    for serial in range(3, 4):
        env_process = subprocess.Popen('/home/deep1/Itai_Asaf/minecraft_lifelong_learning/malmo/Minecraft/launchClient.sh -port ' + str(port), shell=True, preexec_fn=os.setsid)
        time.sleep(120)
        subprocess.call([train_script, str(serial), str(depth), str(port)])
        os.killpg(os.getpgid(env_process.pid), signal.SIGTERM)
        port += 1
