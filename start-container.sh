#!/bin/bash
SSH_KEY=$(mktemp ~/.ssh/perlfox_XXXXXX)
PF_HOME=$HOME/.perlfox_home

function cleanup() {
    echo "Cleaning up temporary SSH keys"
    rm $SSH_KEY{,.pub}

    echo -n "Killing docker container: "
    docker kill perlfox-session
    echo -n "Removing docker container: "
    docker rm perlfox-session
    exit
}

# MAIN
# Kill the container on CTRL+C
trap cleanup INT

# Create a homedir for perlfox
mkdir -p $PF_HOME

# Create the SSH key for automatic login
echo -e "y\n" | ssh-keygen -t rsa -N "" -f $SSH_KEY >/dev/null || exit 1
PF_KEY="$(cat ${SSH_KEY}.pub)"

# In order for home directory integration to work, we need the UID/GID to match
MY_GID=$(grep ":${UID}:[0-9]*:" /etc/passwd | awk -F: '{print $4}')

# Run docker container
echo "Pulling and running docker container"
docker pull gizmonicus/perlfox:testing
docker run -d -p 2022:22 \
        -e "MY_GID=$MY_GID" \
        -e "UID=$UID" \
        -e "PF_KEY=$PF_KEY" \
        -v "$PF_HOME:/home/perlfox-user" \
        --name perlfox-session \
    gizmonicus/perlfox:testing >/dev/null

# Wait for SSH to start accepting connections
REPEAT='true'
while "$REPEAT"; do
    ssh -X -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2022 -i $SSH_KEY perlfox-user@localhost 2>/dev/null && REPEAT='false'
done

# Clean up after ourselves
cleanup
