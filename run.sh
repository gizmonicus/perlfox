#!/bin/bash

echo "Adding perlfox-user group with GID $MY_GROUPS"
groupadd -g $MY_GROUPS perlfox-user

echo "Adding perlfox-user with UID $MY_UID"
useradd -u $MY_UID -g $MY_GROUPS -s /bin/bash perlfox-user

su - perlfox-user -c firefox
