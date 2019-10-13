#!/bin/bash

xrandr --output DVI-I-$1 --primary --left-of DVI-I-$((($1 + 1) % 2))
