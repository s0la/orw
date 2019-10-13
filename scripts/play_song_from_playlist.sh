#!/bin/bash

song=$1
title=${song#*- }
artist=${song%% -*}

mpc -q searchplay artist "$artist" title "$title"
