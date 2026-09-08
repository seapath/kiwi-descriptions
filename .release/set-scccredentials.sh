#!/bin/sh
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

set -eu

output_dir="$(dirname "$0")/../.cqfd/sles16.1"

: "${SLES_USERNAME:?SLES_USERNAME is required}"
: "${SLES_PASSWORD:?SLES_PASSWORD is required}"
: "${SLES_TOKEN:?SLES_TOKEN is required}"

cat > "$output_dir/SCCcredentials" <<EOF
username=$SLES_USERNAME
password=$SLES_PASSWORD
system_token=$SLES_TOKEN
EOF

cp "$output_dir/SCCcredentials" "$output_dir/SUSE_Linux_Enterprise_High_Availability_Extension_16.1_x86_64"

chmod 0600 "$output_dir/SCCcredentials"
chmod 0600 "$output_dir/SUSE_Linux_Enterprise_High_Availability_Extension_16.1_x86_64"
