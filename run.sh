#!/bin/bash
PF_HOME=/home/perlfox-user

echo "Adding perlfox-user"
useradd -d $PF_HOME perlfox-user

# Setup perlfox-user keys
mkdir -p /home/perlfox-user/.ssh
echo $PF_KEY > $PF_HOME/.ssh/authorized_keys
chmod 700 $PF_HOME/.ssh && chmod 400 $PF_HOME/.ssh/authorized_keys
chown -R perlfox-user:perlfox-user $PF_HOME/.ssh

# Configure .bashrc
echo -e "firefox; exit\n" >> $PF_HOME/.bashrc

export OPTIONS="-D"
echo "Starting SSH Server; press Ctrl + C to stop."
/etc/init.d/sshd start >/dev/null
