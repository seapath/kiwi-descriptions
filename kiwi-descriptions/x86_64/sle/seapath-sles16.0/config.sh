#!/bin/bash
set -ex

# Kiwi utility functions & variables
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

# An empty machine-id doesn't mean first boot for systemd
# Should be set to "uninitialized"
echo "uninitialized" > /etc/machine-id


# Additional python packages
python3.13 -m pip install \
    podman-compose

# Configure pam

install -m 0440 /usr/lib/pam.d/login /etc/pam.d/login

for i in /etc/pam.d/common-* /etc/pam.d/postlogin-*; do
    # Disable pam-config managed files if found
    if [ -L "$i" ] && [ "$(readlink $i)" = "${i}-pc" ]; then
        rm $i
        sed '/^#.*/d' ${i}-pc > $i;
    fi
done

# Configure user permissions

chown -R admin:admin /home/admin
chown -R ansible:ansible /home/ansible

chmod 0600 /home/admin/.ssh/authorized_keys
chmod 0600 /home/ansible/.ssh/authorized_keys

chmod 0440 /etc/sudoers
chmod 0440 /etc/sudoers.d/ansible

# Configure SSH

baseService sshd on

# Additional configurations

mv /usr/share/vim/vim92/suse.vimrc /etc/vimrc

# Network

baseService systemd-networkd on
baseService systemd-networkd-wait-online off
baseService systemd-resolved on
baseService openvswitch on

# logrotate

if echo "${kiwi_profiles}" | grep -qw "cluster"; then
    rm -f /etc/logrotate.d/cephadm
fi
