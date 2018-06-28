#!/bin/sh
#
# Script for automatic setup of an SS-TPROXY server on CentOS 7.3 Minimal.
# copy from: https://raw.githubusercontent.com/YahuiWong/Usefulfiles/master/install-ss-tproxy.sh
# modified by scorpio
#

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'yum install' failed."; }
bigecho()  { echo; echo -e "\033[36m $1 \033[0m"; }

# Disable FireWall
# bigecho "Disable Firewall..."
# systemctl stop firewalld.service
# systemctl disable firewalld.service

# Install Lib
bigecho "Install Library, Pleast wait..."
yum -y install epel-release initscripts.x86_64 || exiterr2
yum provides '*/applydeltarpm' 
yum -y install deltarpm  
yum -y install git gettext gcc autoconf libtool automake make asciidoc xmlto c-ares-devel libev-devel openssl-devel net-tools curl ipset libcurl-devel iproute perl wget gcc bind-utils vim || exiterr2

# 查找 TPROXY 模块
# find /lib/modules/$(uname -r) -type f -name '*.ko*' | grep 'xt_TPROXY'
# Install haveged
if ! type haveged 2>/dev/null; then
    bigecho "Install Haveged, Pleast wait..."
    HAVEGED_VER=1.9.1-1
    HAVEGED_URL="http://dl.fedoraproject.org/pub/epel/7/x86_64/Packages/h/haveged-$HAVEGED_VER.el7.x86_64.rpm"
    yum -y install "$HAVEGED_URL" || exiterr2
    # yum -y install haveged || exiterr2
fi

# Install dnsmasq
yum -y install dnsmasq || exiterr2

# Build chinadns
if ! type chinadns 2>/dev/null; then
    bigecho "Build chinadns, Pleast wait..."
    CHINADNS_VER=1.3.2
    CHINADNS_FILE="chinadns-$CHINADNS_VER"
    CHINADNS_URL="https://github.com/shadowsocks/ChinaDNS/releases/download/$CHINADNS_VER/$CHINADNS_FILE.tar.gz"
    if ! wget --no-check-certificate -O $CHINADNS_FILE.tar.gz $CHINADNS_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $CHINADNS_FILE.tar.gz
    pushd $CHINADNS_FILE
    ./configure
    make && make install
    popd
fi

# Build Libsodium
if [ ! -f "/usr/lib/libsodium.so" ]; then
    bigecho "Build Libsodium, Pleast wait..."
    LIBSODIUM_VER=1.0.13
    LIBSODIUM_FILE="libsodium-$LIBSODIUM_VER"
    LIBSODIUM_URL="https://download.libsodium.org/libsodium/releases/$LIBSODIUM_FILE.tar.gz"
    if ! wget --user-agent="Mozilla/5.0 (X11;U;Linux i686;en-US;rv:1.9.0.3) Geco/2008092416 Firefox/3.0.3" --no-check-certificate -O $LIBSODIUM_FILE.tar.gz $LIBSODIUM_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $LIBSODIUM_FILE.tar.gz
    pushd $LIBSODIUM_FILE
    ./configure --prefix=/usr && make
    make install
    popd
    ldconfig
fi

# Build MbedTLS
if [ ! -f "/usr/lib/libmbedtls.so" ]; then
    bigecho "Build MbedTLS, Pleast wait..."
    MBEDTLS_VER=2.6.0
    MBEDTLS_FILE="mbedtls-$MBEDTLS_VER"
    MBEDTLS_URL="https://tls.mbed.org/code/releases/$MBEDTLS_FILE-gpl.tgz"
    if ! wget --no-check-certificate -O $MBEDTLS_FILE-gpl.tgz $MBEDTLS_URL; then
        bigecho "Failed to download file!"
        exit 1
    fi
    tar xf $MBEDTLS_FILE-gpl.tgz
    pushd $MBEDTLS_FILE
    make SHARED=1 CFLAGS=-fPIC
    make DESTDIR=/usr install
    popd
    ldconfig
fi

#Build shadowsocks-libev
if ! type ss-redir 2>/dev/null; then
    bigecho "Build shadowsocks-libev, Pleast wait..."
    git clone https://github.com/shadowsocks/shadowsocks-libev.git
    pushd shadowsocks-libev
    git submodule update --init --recursive
	./autogen.sh && ./configure && make
	make install
    popd
fi

# Install SS-TPROXY
if ! type ss-tproxy 2>/dev/null; then
    bigecho "Install SS-TProxy, Pleast wait..."
    git clone https://github.com/zscorpio/ss-tproxy.git
    pushd ss-tproxy
    cp -af ss-tproxy /usr/local/bin/
    cp -af ss-switch /usr/local/bin/
    chown root:root /usr/local/bin/ss-tproxy /usr/local/bin/ss-switch
    chmod +x /usr/local/bin/ss-tproxy /usr/local/bin/ss-switch
    mkdir -m 0755 -p /etc/tproxy
    # cp -af chnroute.txt /etc/tproxy/
    # cp -af chnroute.ipset /etc/tproxy/
    # cp -af ss-tproxy.conf /etc/tproxy/
    chown -R root:root /etc/tproxy
    # chmod 0644 /etc/tproxy/*
    popd

    # Systemctl
    pushd ss-tproxy
    cp -af ss-tproxy.service /etc/systemd/system/
    popd
    #systemctl daemon-reload
    #systemctl enable ss-tproxy.service
fi

# Display info
bigecho "#######################################################"
bigecho "Please modify /etc/tproxy/ss-tproxy.conf before start."
bigecho "#######################################################"
