#!/bin/bash

~/.orw/scripts/barctl.sh -b mw*
~/.orw/scripts/ncmpcpp.sh -w 100 -h 100 -Vv -L "-n visualizer -M mwi x,y,w move -t 300 resize -B" -i
