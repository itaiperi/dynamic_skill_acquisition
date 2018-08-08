#!/bin/bash

# $1 - new agent

rm -r $1
cp -r experiments/d-miner-hunter/ $1
rm $1/log.txt $1/opts.json
