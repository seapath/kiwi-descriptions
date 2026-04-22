FROM registry.suse.com/suse/sle15:15.7

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

ADD SCCcredentials /etc/zypp/credentials.d/SCCcredentials
ENV ADDITIONAL_MODULES=sle-module-development-tools,sle-module-legacy,PackageHub

RUN zypper --gpg-auto-import-keys refresh && zypper install -y --no-recommends \
    binutils \
    gptfdisk \
    jing \
    kiwi-systemdeps-iso-media \
    kpartx \
    lvm2 \
    python311 \
    python311-kiwi \
    sudo \
    systemd \
    xz

ADD kiwi.yml /etc/kiwi.yml

RUN echo '%builders    ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
