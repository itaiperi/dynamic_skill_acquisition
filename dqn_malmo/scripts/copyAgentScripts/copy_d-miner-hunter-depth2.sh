#!/bin/bash

# $1 - new agent

rm -r $1
cp -r experiments/d-miner-hunter-depth2/ $1
