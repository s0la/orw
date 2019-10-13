#!/bin/bash

until [[ $(wmctrl -l | awk '$NF == "'$1'" {print "running"}') ]]; do continue; done
shift
eval "$@"
