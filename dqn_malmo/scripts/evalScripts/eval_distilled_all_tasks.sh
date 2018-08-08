#!/bin/bash

# $1 = id
# $2 = port

cp $DQNF/experiments/$1/scores.t7 $DQNF/experiments/$1/scores_train.t7

printf 'y\ny\n' | $DQNF/evalScripts/evalScript.sh $1 miner.xml 1 $2
mv $DQNF/experiments/$1/eval_scores.t7 $DQNF/experiments/$1/scores_mine.t7

printf 'y\ny\n' | $DQNF/evalScripts/evalScript.sh $1 hunter.xml 2 $2
mv $DQNF/experiments/$1/eval_scores.t7 $DQNF/experiments/$1/scores_hunt.t7

printf 'y\ny\n' | $DQNF/evalScripts/evalScript.sh $1 cooker.xml 3 $2
mv $DQNF/experiments/$1/eval_scores.t7 $DQNF/experiments/$1/scores_cook.t7