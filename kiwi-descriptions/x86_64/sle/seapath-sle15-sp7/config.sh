#!/bin/bash
set -ex

# Kiwi utility functions
test -f /.kconfig && . /.kconfig

#======================================
# Activate services
#--------------------------------------
baseService sshd on
