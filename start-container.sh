#!/bin/bash
XSOCK=/tmp/.X11-unix
MYXAUTH=$(mktemp /tmp/.docker_xauthXXXXXX)
touch $MYXAUTH
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f $MYXAUTH nmerge -

docker run -it \
        --volume=$XSOCK:$XSOCK:rw \
        --volume=$MYXAUTH:$MYXAUTH:rw \
        --env="XAUTHORITY=${MYXAUTH}" \
        --env="DISPLAY" \
        --env=MY_UID=$UID \
        --env=MY_GROUPS=$GROUPS \
        gizmonicus/perlfox
