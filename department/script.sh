#!/usr/bin/env bash

# error handling
set -euo pipefail

# root access
if [ "$(id -u)" != 0 ]; then
    echo "Error: root permissions required" >&2
    exit 1
fi

# greetings
cat <<EOF
Welcome!
Read the department groups below
it group = developers team (docker, nginx)
sec group = cybersecurity team (tcpdump, journalctl)
lead group = team leads (full root access)
EOF


# function
create_user() {
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
}


if ! [ -z "echo ./users" ]; then
  for line in $(cat ./users); do
  USER_1=$(echo $line | cut -d' ' -f1)
  GROUP_1=$(echo $line | cut -d' ' -f2)
  create_user; done
else
  read -p "Print username: " USER_1
  read -p "Print groupname: " GROUP_1
  create_user
fi

# Interactive selection (select, case)
select number in "Add new user from ./users" "Add new user interactively" "Show last 5 users" "Show last 5 groups" "Exit"; do
case $number in
  "Add new user from ./users")
                if [ -z $(cat ./users &> /dev/null) ]; then
                   echo "Undefined variables, check your ./users file"
                else
                   for line in $(cat ./users); do
                   USER_1=$(echo $line | cut -d' ' -f1)
                   GROUP_1=$(echo $line | cut -d' ' -f2)
                   create_user; done
                fi ;;
  "Add new user interactively")
                  read -p "Print username: " USER_1
                  read -p "Print groupname: " GROUP_1
                  create_user ;;
  "Show last 5 users") tail -n 5 /etc/passwd ;;
  "Show last 5 groups") tail -n 5 /etc/group ;;
  "Exit") break ;;
  *) echo Wrong option ;;
esac
done
