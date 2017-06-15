#!/bin/bash
PF_HOME=/home/perlfox-user

echo "Making homedir (if it doesn't exist)"
mkdir -p /home/perlfox-user

echo "Adding perlfox-user group with GID $MY_GID"
groupadd -g $MY_GID perlfox-user

echo "Adding perlfox-user with UID $MY_UID"
useradd -u $MY_UID -g $MY_GID -d $PF_HOME perlfox-user

# Setup perlfox-user keys
mkdir -p /home/perlfox-user/.ssh
echo $PF_KEY > $PF_HOME/.ssh/authorized_keys
chmod 700 $PF_HOME/.ssh && chmod 400 $PF_HOME/.ssh/authorized_keys && chmod 700 $PF_HOME
chown -R perlfox-user:perlfox-user $PF_HOME/.ssh

# Configure .bashrc, if one doesn't exist
test -f $PF_HOME/.bashrc || \
    cp /etc/skel/.bashrc $PF_HOME/.bashrc && \
    chown perlfox-user:perlfox-user $PF_HOME/.bashrc

# Configure .bash_profile, if one doesn't exist
test -f $PF_HOME/.bash_profile || \
    cp /etc/skel/.bash_profile $PF_HOME/.bash_profile && \
    chown perlfox-user:perlfox-user $PF_HOME/.bash_profile

export OPTIONS="-D"
echo "Starting SSH Server; press Ctrl + C to stop."
/etc/init.d/sshd start >/dev/null
