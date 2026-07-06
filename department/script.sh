#!/usr/bin/env bash

# error handling
set -euo pipefail

# root access
if [ "$(id -u)" != 0 ]; then
    echo "Error: root permissions required" >&2
    exit 1
fi

cat <<EOF
Welcome!
Read the department groups below
it group = developers team (docker, nginx)
sec group = cybersecurity team (tcpdump, journalctl)
lead group = team leads (full root access)
EOF

read -p "Print username: " USER_1
read -p "Print groupname: " GROUP_1

if ! getent group "$GROUP_1" &>/dev/null; then # getent prevents if group exists
    groupadd "$GROUP_1"
fi

shell=/sbin/nologin
privileges=""

# privelegies for departments
case "$GROUP_1" in
    it)
        shell=/bin/bash
        privileges="/usr/bin/docker, /usr/bin/nginx, /usr/bin/systemctl"
        ;;
    sec)
        shell=/bin/bash
        privileges="/usr/bin/tcpdump, /usr/bin/journalctl, /usr/sbin/nft, /usr/sbin/iptables"
        ;;
    lead)
        shell=/bin/bash
        privileges="ALL"
        ;;
    *)
        ;;
esac

# group
if [ -n "$privileges" ]; then
    if ! grep -q "^%${GROUP_1}[[:space:]]" /etc/sudoers; then
        cp /etc/sudoers /etc/sudoers.bkp
        echo "%${GROUP_1}  ALL=(ALL:ALL) $privileges" >> /etc/sudoers
    fi
    echo "$USER_1 is root now, because group is $GROUP_1"
else
    echo "$USER_1 will be created with restricted access (no sudo)"
fi

# user
if ! id "$USER_1" &>/dev/null; then
    useradd -m -g "$GROUP_1" -s "$shell" "$USER_1"
else
    echo "$USER_1 already exists!" >&2
    exit 1
fi

