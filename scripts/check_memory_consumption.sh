#!/bin/bash

ps aux | awk '!/'${0##*/}'/ && /'$1'/ { print int($6 / 1024) }'
