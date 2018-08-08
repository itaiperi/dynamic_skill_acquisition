#!/bin/bash

# $1 - new agent id

rm -r experiments/$1
cp -r experiments/d-miner/ experiments/$1
rm experiments/$1/log.txt experiments/$1/opts.json
