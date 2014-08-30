#!/bin/bash

usage="calls: bc -ql and removes some decimals if necessary..."

if [[ $# -eq 0 || "$1" = "--help" || "$1" = "-h" ]]; then
    echo -e $usage
    exit 1
fi

# different sed regex option for mac/linux
# we'll check in case we haven't installed gnu sed yet
sys=$(uname -s)
if [[ "$sys" = "Linux" || -n "$(which gsed)" ]]; then
    opt=-r
else
    opt=-E
fi

echo "$*" | bc -ql | sed $opt 's/(\.[0-9]{0,3})[0-9]*/\1/'
