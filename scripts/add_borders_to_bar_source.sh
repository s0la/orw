#!/bin/bash

bar_source=${1-~/Downloads/bar/lemonbar.c}

sed -i 's/\(static.* bgc,\)\(.*\)/\1 bbgc,\2/' $bar_source
sed -i '/static.* bgc/i static int bsize = 0;' $bar_source
sed -i '/ret->x/ s/0/bsize/' $bar_source
sed -i 's/bgc.v/bbgc.v/2' $bar_source

sed -i 's/\(getopt.*:\)\(.*\)/\1R:r:\2/' $bar_source
sed -i "/case 'U'.*NULL/a \\\t\t\tcase 'R': bbgc = parse_color(optarg, NULL, (rgba_t)0x00000000U); break;" $bar_source
sed -i "/case 'R'.*NULL/a \\\t\t\tcase 'r': bsize = strtoul(optarg, NULL, 10); break;" $bar_source
