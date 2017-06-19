#!/bin/bash
# Smarter debug
set -o xtrace
PF_HOME=/home/perlfox-user

# Create the perlfox user
mkdir -p /home/perlfox-user
groupadd -g $MY_GID perlfox-user
useradd -u $MY_UID -g $MY_GID -d $PF_HOME perlfox-user

# Setup perlfox-user keys
mkdir -p /home/perlfox-user/.ssh
echo $PF_KEY > $PF_HOME/.ssh/authorized_keys
chmod 700 $PF_HOME/.ssh && chmod 400 $PF_HOME/.ssh/authorized_keys && chmod 700 $PF_HOME

# Configure .bashrc, if one doesn't exist
test -f $PF_HOME/.bashrc || \
    cp /etc/skel/.bashrc $PF_HOME/.bashrc

# Configure .bash_profile, if one doesn't exist
test -f $PF_HOME/.bash_profile || \
    cp /etc/skel/.bash_profile $PF_HOME/.bash_profile

# Set perlfox-user as homedir owner
chown -R perlfox-user:perlfox-user $PF_HOME

echo "Starting SSH Server; press Ctrl + C to stop."
OPTIONS="-D" /etc/init.d/sshd start >/dev/null
