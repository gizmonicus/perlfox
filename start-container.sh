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
    docker rm -v perlfox-session
    exit
}

# MAIN
read -d '' -r HELPTEXT <<EOF
Perlfox - A dockerized implementation of Firefox with support for the dreaded Java plugin.
Usage: $(basename $0) [options] document_root
  -h Display this message.
  -p Use this port for binding sshd to the host network stack (default 2022)
  -c Command to run when starting the container (default is firefox)
  -d A space separated list of DNS servers to use (default is to mount /etc/resolv.conf). Multiple DNS servers must be quoted: "1.1.1.1 2.2.2.2".
  -s List of search domains to use in /etc/resolv.conf (default is null). You must configure -d to use this option. Multiple domains must be quoted: "test.com sub.test.com"
EOF

CONFIGURE_DNS=false
DNS_SERVERS=""
SEARCH_DOMAINS=""
SSH_COMMAND="/usr/bin/firefox"
SSHD_PORT=2022

while getopts c:d:s:p:h OPTION
do
    case $OPTION in
    c)
        SSH_COMMAND=$OPTARG
        ;;
    d)
        DNS_SERVERS=$OPTARG
        CONFIGURE_DNS=true
        ;;
    s)
        SEARCH_DOMAINS=$OPTARG
        ;;
    p)
        SSHD_PORT=$OPTARG
        ;;
    h)
      echo "$HELPTEXT"
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

# Set DNS servers
echo ">> Setting DNS options"
if $CONFIGURE_DNS; then
    if [ -n "$DNS_SERVERS" ]; then
        echo "Using DNS servers: $DNS_SERVERS" | indent
        for SERVER in $DNS_SERVERS; do
            DNS_OPTS="$DNS_OPTS --dns=$SERVER"
        done
    else
        echo "Using DNS servers: 8.8.8.8 8.8.4.4" | indent
        DNS_OPTS="$DNS_OPTS --dns=8.8.8.8 --dns=8.8.4.4"
    fi

# Set DNS search domains
    if [ -n "$SEARCH_DOMAINS" ]; then
        echo "Search domain overriden: $SEARCH_DOMAINS" | indent
        for DOMAIN in $SEARCH_DOMAINS; do
            DNS_OPTS="$DNS_OPTS --dns-search=$DOMAIN"
        done
    fi
else
    echo "Using host's /etc/resolv.conf" | indent
    DNS_OPTS="-v /etc/resolv.conf:/etc/resolv.conf"
fi

# Run docker container
echo ">> Pulling docker container"
docker pull gizmonicus/perlfox:latest | indent
echo ">> Running docker container"
docker run -d -p $SSHD_PORT:22 \
        -e "MY_GID=$MY_GID" \
        -e "MY_UID=$UID" \
        -e "PF_KEY=$PF_KEY" \
        -v "$PF_HOME:/home/perlfox-user" \
        $DNS_OPTS \
        --name perlfox-session \
    gizmonicus/perlfox:dns | indent

# Wait for SSH to start accepting connections
REPEAT='true'
COUNT='0'
LIMIT='10'
while "$REPEAT"; do
    # Disable host checking to prevent key mismatch. Don't save the host in known hosts file.
    ssh -X -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p $SSHD_PORT -i $SSH_KEY perlfox-user@localhost "$SSH_COMMAND" 2>/dev/null && REPEAT='false'

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
