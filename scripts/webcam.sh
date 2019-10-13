#!/bin/bash

mplayer -tv driver=v4l2:width=400:height=250:device=/dev/video0 -vo xv tv:// -geometry "97%:93%" -noborder -ontop
