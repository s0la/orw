#!/bin/bash

song=${1#[![:ascii:]]}
title=${song#*- }
artist=${song%% -*}

mpc -q searchplay artist "$artist" title "$title"
