import os

import matplotlib.pyplot as plt
from matplotlib.ticker import MultipleLocator
import numpy as np
from torch.utils.serialization import load_lua


def read_agent_instances_file(file_path, file_name):
    files_data = [load_lua(os.path.join(file_path + ('.%d' % i), file_name)) for i in range(3)]
    # files_data = [load_lua(os.path.join(file_path + ('.%d' % i), file_name)) for i in range(0,1)]
    for file_data in files_data:
        for i in range(len(file_data)):
            if 0 >= file_data[i] >= -40:
                # print file_path
                file_data[i] += 1000
            # file_data[i] = 1 if file_data[i] > 0 else 0
    min_length = min(min([len(data) for data in files_data]), 42)
    files_data = [data[:min_length] for data in files_data]

    return np.stack(files_data, axis=0)


# Paths of cooker agents
# base_dir = os.path.join(os.environ['DQNF'], 'experiments/SCORES_6.4.18')
base_dir = os.path.join(os.environ['DQNF'], 'experiments')
# base_dir = '.'
cookers_paths = [
    os.path.join(base_dir, 'd-miner-hunter-depth1-no-gs'),
    os.path.join(base_dir, 'd-miner-hunter-depth2-no-gs'),
    os.path.join(base_dir, 'd-miner-hunter-depth1'),
    os.path.join(base_dir, 'd-miner-hunter-depth2'),
    # os.path.join(base_dir, 'distilled.depth1'),
    os.path.join(base_dir, 'cooker')
]
miner_path = os.path.join(base_dir, 'miner')
hunter_path = os.path.join(base_dir, 'hunter')

# Graph of training scores
training_scores = [read_agent_instances_file(cooker_path, 'scores.t7') for cooker_path in cookers_paths if 'distilled' not in cooker_path]
training_scores = [np.mean(scores, axis=0) for scores in training_scores]

cookers_legend = (
    'online-distilled-1',
    'online-distilled-2',
    'frozen-online-distilled-1',
    'frozen-online-distilled-2',
    'distilled',
    'domain-expert'
)

max_epochs = 0
plt.figure()
for training_score in training_scores:
    # print len(training_score), training_score[0], training_score[1]
    epochs = np.arange(1, training_score.shape[-1] + 1)
    max_epochs = max_epochs if max_epochs > epochs[-1] else epochs[-1]
    plt.plot(epochs, training_score)
plt.xlabel('Epoch')
plt.axes().xaxis.set_minor_locator(MultipleLocator(2))
plt.ylabel('Score')
plt.title('Validation score as function of epoch')
plt.legend(cookers_legend, loc=5)
plt.savefig('train_score.png')

# Export training scores to CSV, so we can import easily to presentation
training_scores = [np.pad(training_score, (0, max_epochs - training_score.shape[0]), mode='constant',
                          constant_values=-1000) for training_score in training_scores]
with open('training_scores.csv', 'w') as f:
    for epoch_scores in zip(*training_scores):
        f.write(','.join([str(elem) for elem in epoch_scores]) + '\n')

# Bar chart of average score of all tasks, averaged over 3 trained agents, of each type of distilled agent
scores = []
errs = []
for cooker_path in cookers_paths[:-1]:
    # We only look at distilled, we don't look at regular
    mine_score = np.mean(read_agent_instances_file(cooker_path, 'scores_mine.t7'), axis=1)
    hunt_score = np.mean(read_agent_instances_file(cooker_path, 'scores_hunt.t7'), axis=1)
    cook_score = np.mean(read_agent_instances_file(cooker_path, 'scores_cook.t7'), axis=1)
    scores_3_agents = np.stack([mine_score, hunt_score, cook_score], axis=0)
    scores.append(np.mean(scores_3_agents))
    errs.append(np.std(np.mean(scores_3_agents, axis=0)))
mine_score = np.mean(read_agent_instances_file(miner_path, 'scores_mine.t7'), axis=1)
hunt_score = np.mean(read_agent_instances_file(hunter_path, 'scores_hunt.t7'), axis=1)
cook_score = np.mean(read_agent_instances_file(cookers_paths[-1], 'scores_cook.t7'), axis=1)
scores_3_agents = np.stack([mine_score, hunt_score, cook_score], axis=0)
scores.append(np.mean(scores_3_agents))
errs.append(np.std(np.mean(scores_3_agents, axis=0)))

plt.figure()
# plt.bar(np.arange(6), scores, yerr=errs)
# for i, v in zip(np.arange(6), scores):
plt.bar(np.arange(5), scores, yerr=errs)
for i, v in zip(np.arange(5), scores):
    plt.gca().text(i-0.12, v + 7, str(int(v)))
plt.xticks(np.arange(6), cookers_legend[:-1] + ('baselines',), rotation=18)
plt.title('Average scores of all tasks, for all agents')
plt.ylabel('Average Score')
plt.xlabel('Agent')
plt.gcf().subplots_adjust(bottom=0.23)
plt.savefig('average_tasks_score.png')

# Bar chart of score per task, averaged over 3 trained agents, of each type of distilled agent. Also show scores of
# regular agents
scores = []
errs = []
plt.figure()
x_index = 0.5
for cooker_path in cookers_paths[:-1]:
    # We only look at distilled, we don't look at regular
    mine_score = np.mean(read_agent_instances_file(cooker_path, 'scores_mine.t7'), axis=1)
    hunt_score = np.mean(read_agent_instances_file(cooker_path, 'scores_hunt.t7'), axis=1)
    cook_score = np.mean(read_agent_instances_file(cooker_path, 'scores_cook.t7'), axis=1)
    plt.bar(x_index - 0.2, np.mean(mine_score), width=0.2, align='center', color='C0')#, yerr=np.std(mine_score))
    plt.bar(x_index, np.mean(hunt_score), width=0.2, align='center', color='C1')#, yerr=np.std(hunt_score))
    plt.bar(x_index + 0.2, np.mean(cook_score), width=0.2, align='center', color='C2')#, yerr=np.std(cook_score))
    plt.gca().text(x_index - 0.3, max([np.mean(mine_score), 0]) + 7, str(int(np.mean(mine_score))), size='x-small')
    plt.gca().text(x_index - 0.1, max([np.mean(hunt_score), 0]) + 7, str(int(np.mean(hunt_score))), size='x-small')
    plt.gca().text(x_index + 0.1, max([np.mean(cook_score), 0]) + 7, str(int(np.mean(cook_score))), size='x-small')
    x_index += 1

# Add the regular agents' scores
mine_score = np.mean(read_agent_instances_file(miner_path, 'scores_mine.t7'), axis=1)
hunt_score = np.mean(read_agent_instances_file(hunter_path, 'scores_hunt.t7'), axis=1)
cook_score = np.mean(read_agent_instances_file(cookers_paths[-1], 'scores_cook.t7'), axis=1)

plt.bar(x_index - 0.2, np.mean(mine_score), width=0.2, align='center', color='C0')#, yerr=np.std(mine_score))
plt.bar(x_index, np.mean(hunt_score), width=0.2, align='center', color='C1')#, yerr=np.std(hunt_score))
plt.bar(x_index + 0.2, np.mean(cook_score), width=0.2, align='center', color='C2')#, yerr=np.std(cook_score))
plt.gca().text(x_index - 0.3, max([np.mean(mine_score), 0]) + 7, str(int(np.mean(mine_score))), size='x-small')
plt.gca().text(x_index - 0.1, max([np.mean(hunt_score), 0]) + 7, str(int(np.mean(hunt_score))), size='x-small')
plt.gca().text(x_index + 0.1, max([np.mean(cook_score), 0]) + 7, str(int(np.mean(cook_score))), size='x-small')

plt.xticks(np.arange(5)+0.5, cookers_legend[:-1] + ('baselines',), rotation=18)
plt.legend(['mine', 'hunt', 'cook'], loc=4)
plt.title('Scores per task, for all agents')
plt.ylabel('Score')
plt.xlabel('Agent')
plt.gcf().subplots_adjust(bottom=0.23)
plt.savefig('score_per_task.png')
