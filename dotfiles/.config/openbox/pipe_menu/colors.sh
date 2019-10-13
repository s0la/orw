#!/bin/bash

echo "<openbox_pipe_menu>"

cd ~/.config/orw/colorschemes
for colorscheme in $(ls *.ocs | cut -d '.' -f 1); do
    echo -e "<menu execute='~/.config/openbox/pipe_menu/color_modules.sh $color' id='$colorscheme' label='${colorscheme//_/__}'/>"
done

echo "</openbox_pipe_menu>"
