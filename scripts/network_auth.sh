#!/bin/bash

network_name="$@"

echo "Please enter password for $network_name"
read -sp 'Password: ' password

auth=~/.orw/scripts/auth
path=$auth/networks

[[ -d $root ]] || mkdir $auth
[[ -f $path ]] || touch $path

awk -i inplace -F ':' '\
	BEGIN {
		p = "'"$password"'"
		nn = "'"$network_name"'"
	}
	{
		e = ($1 == nn)
		if(e) c = 1
		print e ? gensub($2, " " p, 1) : $0
	} ENDFILE { if(!c) printf "%s: %s\n", nn, p }' $path

chmod 600 $path
