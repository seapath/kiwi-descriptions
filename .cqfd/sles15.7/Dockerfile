FROM registry.suse.com/suse/sle15:15.7

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Replace base product -- SLES to SLE_RT
RUN zypper rm -y sles-release
ADD SLE_RT.prod /etc/products.d/SLE_RT.prod
RUN ln -s SLE_RT.prod /etc/products.d/baseproduct

ADD SCCcredentials /etc/zypp/credentials.d/SCCcredentials
ENV ADDITIONAL_MODULES=sle-module-rt,sle-module-development-tools,sle-module-server-applications,PackageHub

RUN zypper --gpg-auto-import-keys refresh && zypper install -y --no-recommends \
    binutils \
    gptfdisk \
    jing \
    kiwi-systemdeps-iso-media \
    kpartx \
    lvm2 \
    python311 \
    python311-kiwi \
    SLE_RT-release \
    sudo \
    systemd \
    xz

ADD kiwi.yml /etc/kiwi.yml

RUN echo '%builders    ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
