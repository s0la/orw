#!/bin/bash

base_command="$1"
shift

function make_item() {
	cat <<- EOF
		<item label="${1//_/ }">
		<action name="Execute">
		<execute>$base_command $2</execute>
		</action>
		</item>
	EOF
}

function make_menu() {
    for item in "$@"; do
        make_item ${item%% *} "${item#* }"
    done
}

cat <<- EOF
	<openbox_pipe_menu>
    $(make_menu "$@")
    </openbox_pipe_menu>
EOF
