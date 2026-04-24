FROM registry.suse.com/bci/bci-base:16.0

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ADD SCCcredentials /etc/zypp/credentials.d/SCCcredentials
ENV ADDITIONAL_MODULES=PackageHub

RUN zypper --gpg-auto-import-keys refresh && zypper install -y --no-recommends \
    binutils \
    gawk \
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
