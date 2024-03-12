#!/bin/bash

set -o nounset

ANSIBLEUSER_HOME=/var/lib/ansibleuser
ANSIBLEUSER_INC="$(dirname "$0")/settings/ansibleuser.inc.sh"
ANSIBLEUSER_PUBKEY="$(dirname "$0")/settings/ansibleuser_id_ed25519.pub"

if ! [ -f "$ANSIBLEUSER_INC" ]; then
    echo "ERROR: config file [$ANSIBLEUSER_INC] is required!"
    return
fi

if ! [ -f "$ANSIBLEUSER_PUBKEY" ]; then
    echo "ERROR: public-key file [$ANSIBLEUSER_PUBKEY] is required!"
    return
fi

source "$ANSIBLEUSER_INC"

chroot "$TGT_ROOT" adduser \
    --system \
    --ingroup sudo \
    --home "$ANSIBLEUSER_HOME" \
    --shell /bin/bash \
    --gecos "Ansible 'sudo' User" \
    ansibleuser

# install the user's public key for ssh-auth:
mkdir -pv "$TGT_ROOT/$ANSIBLEUSER_HOME"/.ssh
chmod go-rwx "$TGT_ROOT/$ANSIBLEUSER_HOME"/.ssh
cp "$ANSIBLEUSER_PUBKEY" "$TGT_ROOT/$ANSIBLEUSER_HOME"/.ssh/authorized_keys
chroot "$TGT_ROOT" chown -R ansibleuser "$ANSIBLEUSER_HOME"/.ssh

# setting a password is required to use Ansible's "become" mechanism:
echo "ansibleuser:$ANSIBLE_USER_PW" | chroot "$TGT_ROOT" chpasswd
