#!/bin/bash
set -ex

# Kiwi utility functions
test -f /.kconfig && . /.kconfig

# An empty machine-id doesn't mean first boot for systemd
# Should be set to "uninitialized"
echo "uninitialized" > /etc/machine-id

# Configure SSH

chown admin:admin /home/admin/.ssh/authorized_keys
chown ansible:ansible /home/ansible/.ssh/authorized_keys

chmod 0600 /home/admin/.ssh/authorized_keys
chmod 0600 /home/ansible/.ssh/authorized_keys

baseService sshd on

# Network

baseService systemd-networkd on
baseService systemd-networkd-wait-online off
baseService systemd-resolved on
