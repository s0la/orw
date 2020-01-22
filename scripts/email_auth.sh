#!/bin/bash

echo "Please enter your email credentials"
read -p 'Username: ' username
read -sp 'Password: ' password

auth=~/.orw/scripts/auth
path=$auth/email

[[ -d $root ]] || mkdir $auth

cat <<- EOF > $path
username: $username
password: $password
EOF

echo

chmod 600 $path
