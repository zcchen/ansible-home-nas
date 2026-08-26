#! /bin/bash

export NAME="${SAMBA_SHARENAME:-Data}"
export USER="${SAMBA_USERNAME:-samba}"
export PASS="${SAMBA_PASSWORD:-secret}"

exec /sbin/tini -- /usr/bin/samba.sh

