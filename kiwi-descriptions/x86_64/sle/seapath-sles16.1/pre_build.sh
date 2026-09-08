#!/bin/bash
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

# This script isn't part of a standard KIWI-NG hook
# Parameters:
# $1: KIWI appliance description directory path

KIWI_DESCRIPTION="$1"

get_latest_package_version() {
    # Fourth field is the version.
    # Zypper already sorts packages from the latest version to the oldest.
    zypper -q se -x --details $1 | tail -n+4 |\
        grep "SLE-Product" |\
        head -n1 | cut -d'|' -f4 |\
        tr -d " "
}

SYSTEMD_VERSION=$(get_latest_package_version systemd)
QEMU_VERSION=$(get_latest_package_version qemu-x86)

cp $KIWI_DESCRIPTION/packages-dynamic.xml.in $KIWI_DESCRIPTION/packages-dynamic.xml
sed -i "s/@@SYSTEMD_VERSION@@/${SYSTEMD_VERSION}/g" $KIWI_DESCRIPTION/packages-dynamic.xml
sed -i "s/@@QEMU_VERSION@@/${QEMU_VERSION}/g" $KIWI_DESCRIPTION/packages-dynamic.xml
