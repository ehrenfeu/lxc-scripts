#!/bin/bash

set -o nounset

ANSIBLEUSER_INC="$(dirname "$0")/settings/ansibleuser.inc.sh"
if ! [ -f "$ANSIBLEUSER_INC" ]; then
    echo "ERROR: config file [$ANSIBLEUSER_INC] is required!"
    return
fi

source "$ANSIBLEUSER_INC"

chroot "$TGT_ROOT" adduser \
    --system \
    --ingroup sudo \
    --home /var/lib/ansibleuser \
    --shell /bin/bash \
    --gecos "Ansible 'sudo' User" \
    ansibleuser

echo "ansibleuser:$ANSIBLE_USER_PW" | chroot "$TGT_ROOT" chpasswd
