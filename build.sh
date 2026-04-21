#!/usr/bin/bash

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

ARGS=$(getopt -o "hse:" -l "add-sle,extra-build-args:" -n "build.sh" -- "$@")
eval set -- "$ARGS"

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
  -e, --extra-build-args    Extra arguments to pass to the 'kiwi system build' command.
  -h                        Show this help message and exit.
EOF
        exit 0
        ;;
    -s|--add-sle)
        if cat /etc/os-release | grep -q 'NAME="SLES"'; then
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
    --)
        shift
        KIWI_DESCRIPTION="$1"
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

# Get SLE repositories from the local system
if [ -n "$ADD_SLE_REPOS" ]; then
    log info "Adding SLE repositories from the local system to the built appliance."

    # - Only use enabled repositories
    # - Get repositories names and URIs
    # - Filter SLE repositories and SUSE package hub
    # - Extract URIs
    SLES_REPOS_URIS="$(
        zypper lr -Eu |\
        cut -d'|' -f3,7 |\
        grep -E "^\s*(SLE|SUSE-PackageHub)[^A-Za-z]" |\
        cut -d'|' -f2
    )"

    for i in $SLES_REPOS_URIS; do
        KIWI_BUILD_ARGS="$KIWI_BUILD_ARGS --add-repo $i"
    done
fi

# Build image
sudo kiwi-ng system build $KIWI_BUILD_ARGS $KIWI_EXTRA_ARGS

# Give ownership and permissions of build artifacts to current user
sudo chown -R $USER \
    build \
    *.changes \
    *.install.iso \
    *.packages \
    *.raw \
    *.verified \
    kiwi.result*
sudo chmod -R u+w build
