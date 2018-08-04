import os

import numpy as np
from torch.utils.serialization import load_lua


def read_agent_instances_file(file_path, file_name):
    files_data = [load_lua(os.path.join(file_path + ('.%d' % i), file_name)) for i in range(3)]
    # files_data = [load_lua(os.path.join(file_path + ('.%d' % i), file_name)) for i in range(2)]
    # files_data = [load_lua(os.path.join(file_path + ('.%d' % i), file_name)) for i in range(1)]
    for file_data in files_data:
        for i in range(len(file_data)):
            if 0 >= file_data[i] >= -40:
                # print file_path
                file_data[i] += 1000
    min_length = min(min([len(data) for data in files_data]), 50)
    files_data = [data[:min_length] for data in files_data]

    return np.stack(files_data, axis=0)


# Paths of cooker agents
base_dir = os.path.join(os.environ['DQNF'], 'experiments')
cookers_paths = [
    os.path.join(base_dir, 'd-miner-hunter-depth1-no-gs'),
    os.path.join(base_dir, 'd-miner-hunter-depth2-no-gs'),
    # os.path.join(base_dir, 'distilled.depth1'),
    os.path.join(base_dir, 'd-miner-hunter-depth1'),
    os.path.join(base_dir, 'd-miner-hunter-depth2'),
    os.path.join(base_dir, 'cooker')
]
miner_path = os.path.join(base_dir, 'miner')
hunter_path = os.path.join(base_dir, 'hunter')

print 'Distilled agents performance:'
for cooker_path in cookers_paths[:-1]:
    mine_scores = read_agent_instances_file(cooker_path, 'scores_mine.t7')
    hunt_scores = read_agent_instances_file(cooker_path, 'scores_hunt.t7')
    cook_scores = read_agent_instances_file(cooker_path, 'scores_cook.t7')
    for i in range(3):
        print '%s.%d %d %d %d' % (cooker_path, i, np.mean(mine_scores[i]), np.mean(hunt_scores[i]), np.mean(cook_scores[i]))

mine_scores = read_agent_instances_file(miner_path, 'scores_mine.t7')
hunt_scores = read_agent_instances_file(hunter_path, 'scores_hunt.t7')
cook_scores = read_agent_instances_file(cookers_paths[-1], 'scores_cook.t7')
for i in range(3):
    print '%s.%d %d' % (miner_path, i, np.mean(mine_scores[i]))
    print '%s.%d %d' % (hunter_path, i, np.mean(hunt_scores[i]))
    print '%s.%d %d' % (cookers_paths[-1], i, np.mean(cook_scores[i]))