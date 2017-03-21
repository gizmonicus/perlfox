#!/bin/bash

echo "Adding perlfox-user group with GID $MY_GID"
groupadd -g $MY_GID perlfox-user

echo "Adding perlfox-user with UID $MY_UID"
useradd -u $MY_UID -g $MY_GID -s /bin/bash perlfox-user

su - perlfox-user -c firefox
