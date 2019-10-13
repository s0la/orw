#!/bin/bash

echo "Please enter your email credentials"
read -p 'Username: ' username
read -sp 'Password: ' password

path=~/.orw/scripts/auth/email

cat <<- EOF > $path
username: $username
password: $password
EOF

echo

chmod 600 $path
