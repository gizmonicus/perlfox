#!/bin/bash

echo -e "Startup:\n---\nCreating homedir for perlfox."
export PERLFOX_HOME=$HOME/.perlfox_home
mkdir -p $PERLFOX_HOME
echo -e "Created directory: $PERLFOX_HOME."

# X11 socket for displaying Firefox UI
XSOCK=/tmp/.X11-unix

# Xauthority file so X11 will actually trust this container.
MYXAUTH=$(mktemp /tmp/.docker_xauthXXXXXX)
echo -e "Configuring xauthority"
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $MYXAUTH nmerge -

# In order for home directory integration to work, we need the UID/GID to match
MY_GID=$(grep ":${UID}:[0-9]*:" /etc/passwd | awk -F: '{print $4}')

echo -e "Detected UID/GID as $UID/$MY_GID"

DOCKER_OPTS="--volume=$XSOCK:$XSOCK
             --volume=$MYXAUTH:$MYXAUTH
             --env=XAUTHORITY=${MYXAUTH}
             --env=DISPLAY
             --env=MY_UID=$UID
             --env=MY_GID=$MY_GID
             --volume $PERLFOX_HOME:/home/perlfox-user"

echo -e "Starting Docker:\n---"
docker run -it $DOCKER_OPTS gizmonicus/perlfox
