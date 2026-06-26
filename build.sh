#!/usr/bin/bash
# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

set -e

SCRIPT_NAME=$(basename "$0")

log() {
    local level="$1"; shift
    local uplevel

    # Sanitize log level
    case "$level" in
        debug|info|warn|error) ;;
        *) level="info" ;;
    esac

    uplevel=$(echo $level | tr '[:lower:]' '[:upper:]')

    echo "[$SCRIPT_NAME] [$uplevel] $*"
}

ARGS=$(getopt -o "hse:o:p:" -l "add-sle,extra-build-args:,global-opts:,profile:,--gh-mask-urls" -n "build.sh" -- "$@")
eval set -- "$ARGS"

GH_MASK_URLS=false

while true; do
    case "$1" in
        -h)
            cat <<EOF
Usage: $0 [options] [kiwi-description]
Arguments:
  kiwi-description: KIWI appliance description directory to build. Will be passed to
Options:
  -s, --add-sle             Add SLE repositories of local system to the built appliance.
                                Relevant only for SLE-based appliances.
  -e, --extra-build-args    Extra build arguments to pass to the 'kiwi-ng system build' command.
  -o, --global-opts         Global options to pass to the 'kiwi-ng' command.
  -p, --profile             Image profile to use. Can be specified multiple times for multiple profiles.
                            Valid profiles:
                                - hypervisor: Image with packages for hypervisor (e.g., KVM, containers).
      --gh-mask-urls        Mask repositories URLs in Github Action logs.
  -h                        Show this help message and exit.
EOF
        exit 0
        ;;
    -s|--add-sle)
        if cat /etc/os-release | grep -q 'NAME="SLE.*"'; then
            ADD_SLE_REPOS=1
        else
            log error "The --add-sle option is only relevant for SLE-based appliances. Ignoring."
        fi
        shift
        ;;
    -e|--extra-build-args)
        KIWI_EXTRA_ARGS="$KIWI_EXTRA_ARGS $2"
        shift 2
        ;;
    -o|--global-opts)
        KIWI_GLOBAL_ARGS="$KIWI_GLOBAL_ARGS $2"
        shift 2
        ;;
    -p|--profile)
        KIWI_BUILD_PROFILES="$KIWI_BUILD_PROFILES $2"
        shift 2
        ;;
    --gh-mask-urls)
        GH_MASK_URLS=true
        shift
        ;;
    --)
        shift
        if [ -d "$1" ]; then
            KIWI_DESCRIPTION="$1"
        else
            log error "Invalid KIWI description directory: $1"
            exit 1
        fi
        break
        ;;
    *)
        echo "Invalid option: $1"
        exit 1
        ;;
    esac
done

# KIWI-NG refuse to build with an existing build/image-root directory
sudo rm -rf build/image-root


KIWI_BUILD_ARGS="--description $KIWI_DESCRIPTION --target-dir ."

for p in $KIWI_BUILD_PROFILES; do
    log info "Enabling \"$p\" profile"
    KIWI_GLOBAL_ARGS="$KIWI_GLOBAL_ARGS --profile $p"
done

# Get SLE repositories from the local system
if [ -n "$ADD_SLE_REPOS" ]; then
    log info "Adding SLE repositories from the local system to the built appliance."

    sudo --preserve-env=ADDITIONAL_MODULES zypper refresh

    # - Only use enabled repositories
    # - Get repositories names and URIs
    # - Filter SLE repositories and SUSE package hub
    SLE_REPOS="$(
        zypper lr -Eu |\
        cut -d'|' -f2,7 |\
        grep -E "^\s*container-suseconnect"
    )"

    # Add repositories to kiwi-ng build
    while read l; do
        ALIAS="$(echo $l | cut -d'|' -f1)"
        URI="$(echo $l | cut -d'|' -f2)"

        if $GH_MASK_URLS; then
            echo "::add-mask::$URI"
        fi

        # Priority order:
        #   - SLE repositories
        #   - SUSE Package Hub
        #   - Other repositories
        if echo "$l" | grep -q "container-suseconnect-zypp:SLE-"; then
            log info "Adding SLE repository $ALIAS"
            KIWI_BUILD_ARGS="$KIWI_BUILD_ARGS --add-repo $URI,,,10"
        elif echo "$l" | grep -q "PackageHub"; then
            log info "Adding PackageHub repository $ALIAS"
            KIWI_BUILD_ARGS="$KIWI_BUILD_ARGS --add-repo $URI,,,50"
        else
            log info "Adding other repository $ALIAS"
            KIWI_BUILD_ARGS="$KIWI_BUILD_ARGS --add-repo $URI,,,70"
        fi
    done <<< "$SLE_REPOS"
fi

# Add SSH keys to root overlay

if [ -f keys/admin_public_ssh_key.pub ]; then
    mkdir -p $KIWI_DESCRIPTION/root/home/admin/.ssh
    cp keys/admin_public_ssh_key.pub $KIWI_DESCRIPTION/root/home/admin/.ssh/authorized_keys
else
    log info "No SSH public key set for admin user"
    rm -rf $KIWI_DESCRIPTION/root/home/admin/.ssh/authorized_keys
fi

if [ -f keys/ansible_public_ssh_key.pub ]; then
    mkdir -p $KIWI_DESCRIPTION/root/home/ansible/.ssh
    cp keys/ansible_public_ssh_key.pub $KIWI_DESCRIPTION/root/home/ansible/.ssh/authorized_keys
else
    log info "No SSH public key set for ansible user"
    rm -rf $KIWI_DESCRIPTION/root/home/ansible/.ssh/authorized_keys
fi

# Build image
log info "Building image with KIWI-NG..."
sudo kiwi-ng $KIWI_GLOBAL_ARGS system build $KIWI_BUILD_ARGS $KIWI_EXTRA_ARGS

DISK_IMAGE_FILE="$(jq -re .disk_image.filename kiwi.result.json)"

# Give ownership and permissions of build artifacts to current user
BUILD_FILES="$(find . -path ./build -prune -o -type f \( \
        -name '*.changes' -o \
        -name '*.install.iso' -o \
        -name '*.packages' -o \
        -name '*.raw' -o \
        -name '*.verified' -o \
        -name 'kiwi.result*' \) -print)"

sudo chown -R $USER build $BUILD_FILES 
sudo chmod -R u+w build


# Generate .bmap and .gz files to be used for flashing with bmaptool
rm -f "$DISK_IMAGE_FILE.bmap" "$DISK_IMAGE_FILE.gz"
if which bmaptool > /dev/null; then
    log info "Generating .raw.bmap and .raw.gz files..."

    bmaptool create -o "$DISK_IMAGE_FILE.bmap" "$DISK_IMAGE_FILE"

    if which pigz > /dev/null; then
        pigz -k "$DISK_IMAGE_FILE"
    else
        log info "Using gzip for compression. Consider installing pigz for faster compression."
        gzip -k "$DISK_IMAGE_FILE"
    fi
else
    log warn "bmaptool not found, skipping .raw.bmap and .raw.gz generation"
fi
