# Copyright (C) 2026 Savoir-faire Linux, Inc.
# SPDX-License-Identifier: Apache-2.0

FROM registry.opensuse.org/opensuse/leap:16.0

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN zypper --gpg-auto-import-keys refresh && zypper install -y --no-recommends \
    binutils \
    gawk \
    git \
    gptfdisk \
    jing \
    jq \
    kiwi-systemdeps-iso-media \
    kpartx \
    lvm2 \
    pigz \
    python3-kiwi \
    python313 \
    python313-bmap-tools \
    sudo \
    systemd \
    which \
    xz

ADD kiwi.yml /etc/kiwi.yml

RUN echo 'ALL    ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
