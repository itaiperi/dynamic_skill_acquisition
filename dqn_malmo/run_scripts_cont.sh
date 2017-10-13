#!/bin/bash

while true; do echo $$; printf "y\ny\n" | ./run_coal_teacher_training.sh $1 $2 $3; done
