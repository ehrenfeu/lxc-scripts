#!/bin/bash

# exit immediately on any error
set -e

usage_exit() {
    echo
    echo "Usage:"
    echo
    echo "    $0 container_name distribution suite"
    echo
    echo "Additional settings (via environment variables):"
    echo
    echo "    Set a MAC address for the container: VM_MAC=ee:ee:ee:01:23:45"
    echo
    echo "Example:"
    echo
    echo "    VM_MAC=ee:ee:ee:01:23:45 $0 revproxy debian 12_bookworm"
    echo
    exit "$1"
}

if [ -z "$1" ] ; then
    echo "ERROR: No name given for container!"
    usage_exit 1
fi
VM_HOSTNAME=$1

if [ -z "$2" ] ; then
    echo "ERROR: No distribution given!"
    usage_exit 2
fi
DISTRIBUTION=$2

if [ -z "$3" ] ; then
    echo "ERROR: No suite for distribution '$DISTRIBUTION' given!"
    usage_exit 2
fi
SUITE=$3

if [ "$4" == "--dry-run" ] ; then
    export DRY_RUN="true"
fi


cd "$(dirname "$0")"
SETUP_SCRIPTS="distributions/$DISTRIBUTION/$SUITE"
if ! [ -d "$SETUP_SCRIPTS" ] ; then
    echo "ERROR: can't find directory [$SETUP_SCRIPTS]!"
    usage_exit 3
fi

# read the global keys symlink:
AUTH_KEYS="${AUTH_KEYS:-$(readlink settings/authorized_keys)}"
# check if there is a suite/configuration specific keys symlink:
if [ -L "distributions/$DISTRIBUTION/$SUITE/settings/authorized_keys" ] ; then
    AUTH_KEYS="$(readlink distributions/"$DISTRIBUTION"/"$SUITE"/settings/authorized_keys)"
fi
if ! [ -r "$AUTH_KEYS" ] ; then
    echo "ERROR: can't find or read authorized keys file: $AUTH_KEYS"
    usage_exit 4
fi
echo AUTH_KEYS="$AUTH_KEYS"

# read the global package cache symlink:
if [ -L "settings/localpkgs" ] ; then
    LOCALPKGS="$(readlink settings/localpkgs)/$DISTRIBUTION/$SUITE"
fi
# check if there is a suite/configuration specific cache symlink:
if [ -L "distributions/$DISTRIBUTION/$SUITE/settings/localpkgs" ] ; then
    LOCALPKGS="$(readlink distributions/"$DISTRIBUTION"/"$SUITE"/settings/localpkgs)"
fi
if [ -n "$LOCALPKGS" ] ; then
    echo LOCALPKGS="$LOCALPKGS"
    export LOCALPKGS
else
    echo "===================================================================="
    echo "WARNING: no 'settings/localpkgs' found, network connection required!"
    echo "===================================================================="
fi

LXCPATH="$(readlink settings/lxcpath)"
if [ -n "$LXCPATH" ] ; then
    echo LXCPATH="$LXCPATH"
    export LXCPATH
else
    echo "WARNING: no 'settings/lxcpath' found, using LXC default!"
fi

LXC_BRIDGE_DEV="${LXC_BRIDGE_DEV:-$(cat settings/bridge_device)}"
echo "LXC_BRIDGE_DEV=$LXC_BRIDGE_DEV"
export LXC_BRIDGE_DEV

RUN_SCRIPT="$SETUP_SCRIPTS/lxc-create-base.sh"
echo -e "----------------------------------\\nLaunching [$RUN_SCRIPT]"
bash "$RUN_SCRIPT" "$VM_HOSTNAME" "$AUTH_KEYS"
echo -e "----------------------------------\\nFinished [$RUN_SCRIPT]"
echo "----------------------------------"
echo

if [ -n "$SUDO_USER" ] ; then
    SUDO_PREFIX="sudo "
fi

echo "Use the following commands to start it and/or check its status:"
echo "  # ${SUDO_PREFIX}lxc-start --lxcpath=$LXCPATH --name=$VM_HOSTNAME -d"
echo "  # ${SUDO_PREFIX}lxc-attach --lxcpath=$LXCPATH --name=$VM_HOSTNAME"
echo "  # ${SUDO_PREFIX}lxc-ls --lxcpath=$LXCPATH --fancy"
echo "  # IPV4=\$(${SUDO_PREFIX}lxc-ls --lxcpath=$LXCPATH --filter=$VM_HOSTNAME --fancy-format=IPV4 --fancy | tail -n 1)"
echo "  # ssh -i ${AUTH_KEYS/.pub/}  root@\$IPV4"
