#!/bin/bash
SSH_KEY=$(mktemp ~/.ssh/perlfox_XXXXXX)

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

# Create the SSH key for automatic login
echo -e "y\n" | ssh-keygen -t rsa -N "" -f $SSH_KEY >/dev/null || exit 1
PF_KEY="$(cat ${SSH_KEY}.pub)"

# Run docker container
echo "Starting Docker"
docker pull gizmonicus/perlfox:testing
docker run -d -p 2022:22 -e "PF_KEY=$PF_KEY" --name perlfox-session gizmonicus/perlfox:testing >/dev/null

# Wait for SSH to start accepting connections
REPEAT='true'
while "$REPEAT"; do
    ssh -X -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2022 -i $SSH_KEY perlfox-user@localhost 2>/dev/null && REPEAT='false'
done

# Clean up after ourselves
cleanup
