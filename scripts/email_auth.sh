#!/bin/bash

echo "Please enter your email credentials"
read -p 'Username: ' username
read -sp 'Password: ' password
read -p $'\nApp password: ' app_password

auth=~/.orw/scripts/auth
path=$auth/email

[[ -d $auth ]] || mkdir $auth

cat <<- EOF > $path
username: $username
password: $password
app_password: $app_password
EOF

echo -e '\nRestarting bar..'
sleep 1

chmod 600 $path
