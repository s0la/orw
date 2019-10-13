#!/bin/bash

state=$(awk -F '=' '/\sstate/ {if ($2 == "rec") print "stop"; else print "rec"}' ~/.orw/bar/si_new.sh)
sed -i "s/\(^file.*\/\)[^\.]*/\1${1:-$(date +'rec_%y-%m-%d:%I:%M')}/" ~/.ssr/settings.conf
sed -i "s/\(.*\sstate=\).*/\1$state/" ~/.orw/bar/si_new.sh
xdotool keydown ctrl key g keyup ctrl
