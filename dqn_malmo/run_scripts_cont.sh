#!/bin/bash

while true; do echo $$; printf "y\ny\n" | $1 $2 ; done
