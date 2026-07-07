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
if ! getent group "$GROUP" &>/dev/null; then # getent prevents if group exists
    groupadd "$GROUP"
fi

shell=/sbin/nologin
privileges=""

# privelegies for departments
case "$GROUP" in
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
    if ! grep -q "^%${GROUP}[[:space:]]" /etc/sudoers; then
        cp /etc/sudoers /etc/sudoers.bkp
        echo "%${GROUP}  ALL=(ALL:ALL) $privileges" >> /etc/sudoers
    fi
    echo "$USER is root now, because group is $GROUP"
else
    echo "$USER will be created with restricted access (no sudo)"
fi

# user
if ! id "$USER" &>/dev/null; then
    useradd -m -g "$GROUP" -c "$BDAY" -s "$shell" "$USER"
else
    echo "$USER already exists!" >&2
    exit 1
fi
}

# Interactive selection (select, case)
select number in "Add new user from ./users" "Add new user interactively" "Show last 5 users" "Show last 5 groups" "Exit"; do
case $number in
  "Add new user from ./users")
                if [ ! -s ./users ]; then
                   echo "Undefined variables, check your ./users file"
                else
                     cut -d',' -f2,3,4,5 users | tail -n +2 | tr 'A-Z' 'a-z' | while IFS=, read -r first_name last_name birthday group_name; do
                     USER="$(echo "$first_name" | cut -c1).$last_name"
                     GROUP="$group_name"
		     BDAY="$birthday"
                     count=2
		     if cut -d':' -f1 /etc/passwd | grep -q "^${USER}$" &> /dev/null; then
			while cut -d':' -f1 /etc/passwd | grep -q "^${USER}_${count}$"; do
                          (( count++ ))
			done
			USER="${USER}_${count}"
		     fi
                       create_user
		  done
                fi ;;
  "Add new user interactively")
                  read -p "Print username: " USER
                  read -p "Print groupname: " GROUP
		  read -p "Print birthday (DD.MM): " BDAY
		  count=2
                    if cut -d':' -f1 /etc/passwd | grep -q "^${USER}$" &> /dev/null; then
                       while cut -d':' -f1 /etc/passwd | grep -q "^${USER}_${count}$"; do
                          (( count++ ))
                        done
                      USER="${USER}_${count}"
                    fi
                  create_user ;;
  "Show last 5 users") tail -n 5 /etc/passwd ;;
  "Show last 5 groups") tail -n 5 /etc/group ;;
  "Exit") break ;;
  *) echo Wrong option ;;
esac
done

