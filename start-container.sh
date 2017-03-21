#!/bin/bash
XSOCK=/tmp/.X11-unix
MYXAUTH=$(mktemp /tmp/.docker_xauthXXXXXX)
touch $MYXAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $MYXAUTH nmerge -

DOCKER_OPTS="--volume=$XSOCK:$XSOCK:rw
             --volume=$MYXAUTH:$MYXAUTH:rw
             --env=XAUTHORITY=${MYXAUTH}
             --env=DISPLAY
             --env=MY_UID=$UID
             --env=MY_GROUPS=$GROUPS"

if [ -n "$PERLFOX_HOME" ]; then
    DOCKER_OPTS="$DOCKER_OPTS -v $PERLFOX_HOME:/home/perlfox-user"
fi

docker run -it $DOCKER_OPTS gizmonicus/perlfox
