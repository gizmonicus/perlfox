#!/bin/bash
function indent() { 
    sed 's/^/  | /' 
}

function success() {
    echo " -> Success"
}

function cleanup() {
    echo -n ">> Cleaning up temporary SSH keys"
    rm ~/.ssh/perlfox_* && success

    echo -n ">> Killing docker container: "
    docker kill perlfox-session
    echo -n ">> Removing docker container: "
    docker rm perlfox-session
    exit
}

# MAIN
HELPTEXT="Perlfox - A dockerized implementation of Firefox with support for\n\
the dreaded Java plugin. Usage:\n\
$(basename $0) [options] document_root\n\
  -h Display this message.\n\
  -d A space separated list of DNS servers to use (default is 8.8.8.8 and 8.8.4.4)\n\
  -s List of search domains to use in /etc/resolv.conf (default is null)"

DNS_SERVERS="8.8.8.8 8.8.4.4"
SEARCH_DOMAINS=""

while getopts d:h OPTION
do
    case $OPTION in
    d)
        DNS_SERVERS=$OPTARG
        ;;
    s)
        SEARCH_DOMAINS=$OPTARG
        ;;
    h)
      echo -e $HELPTEXT
      exit 0
      ;;
    esac
done

SSH_KEY=$(mktemp ~/.ssh/perlfox_XXXXXX)
PF_HOME=$HOME/.perlfox_home

# Kill the container on CTRL+C
trap cleanup INT

# Create a homedir for perlfox
echo -n ">> Creating homedirectory: $PF_HOME"
mkdir -p $PF_HOME && success

# Create the SSH key for automatic login
echo ">> Creating temporary keypair: $SSH_KEY"
echo -e "y\n" | ssh-keygen -t rsa -N "" -f $SSH_KEY | indent || exit 1
PF_KEY="$(cat ${SSH_KEY}.pub)"

# In order for home directory integration to work, we need the UID/GID to match
MY_GID=$(grep ":${UID}:[0-9]*:" /etc/passwd | awk -F: '{print $4}')

# Set DNS options
for SERVER in $DNS_SERVERS; do
    DNS_OPTS="$DNS_OPTS --dns=$SERVER"
done

echo $DNS_OPTS

# Run docker container
echo ">> Pulling docker container"
docker pull gizmonicus/perlfox:latest | indent
echo ">> Running docker container"
docker run -d -p 2022:22 \
        -e "MY_GID=$MY_GID" \
        -e "MY_UID=$UID" \
        -e "PF_KEY=$PF_KEY" \
        -e "DNS_SERVERS=$DNS_SERVERS" \
        -e "SEARCH_DOMAINS=$SEARCH_DOMAINS" \
        -v "$PF_HOME:/home/perlfox-user" \
        --name perlfox-session \
        $DNS_OPTS \
    gizmonicus/perlfox:latest | indent

# Wait for SSH to start accepting connections
REPEAT='true'
COUNT='0'
LIMIT='10'
while "$REPEAT"; do
    # Disable host checking to prevent key mismatch. Don't save the host in known hosts file.
    ssh -X -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p 2022 -i $SSH_KEY perlfox-user@localhost 2>/dev/null && REPEAT='false'

    # Try for $LIMIT seconds
    COUNT=$[COUNT + 1]
    sleep 1
    if [ "$COUNT" -ge "$LIMIT" ]; then
        echo ">> Error connecting to SSH daemon after $COUNT attempts"
        break
    fi
done

# Clean up after ourselves
cleanup
