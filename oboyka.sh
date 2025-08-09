#!/bin/sh

ROOTFS_DIR=/home/container
ALPINE_VERSION="3.22"
ALPINE_FULL_VERSION="3.22.1"
APK_TOOLS_VERSION="2.14.9-r2"
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_ALT=amd64
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_ALT=arm64
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "Alpine đã được cài rồi, skip bước cài đặt"
else
    echo "[*] Đang tải Alpine rootfs..."
    curl -Lo /tmp/rootfs.tar.gz \
        "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/releases/${ARCH}/alpine-minirootfs-${ALPINE_FULL_VERSION}-${ARCH}.tar.gz"

    mkdir -p "$ROOTFS_DIR"
    tar -xzf /tmp/rootfs.tar.gz -C "$ROOTFS_DIR"

    echo "[*] Đang tải apk-tools-static..."
    curl -Lo /tmp/apk-tools-static.apk \
        "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main/${ARCH}/apk-tools-static-${APK_TOOLS_VERSION}.apk"
    mkdir -p /tmp/apk-extract
    tar -xf /tmp/apk-tools-static.apk -C /tmp/apk-extract

    echo "[*] Đang tải proot..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Cài đặt Alpine base system..."
    /tmp/apk-extract/sbin/apk.static \
        -X "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION}/main" \
        -U --allow-untrusted --root "$ROOTFS_DIR" add alpine-base apk-tools

    echo "[*] Set DNS"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    echo "[*] Cleanup..."
    rm -rf /tmp/rootfs.tar.gz /tmp/apk-tools-static.apk /tmp/apk-extract

    touch "$ROOTFS_DIR/.installed"
fi


clear && cat << "EOF"

 ██╗  ██╗ █████╗ ██████╗ ██████╗  ██████╗ ██████╗ 
 ██║  ██║██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔══██╗
 ███████║███████║██████╔╝██████╔╝██║   ██║██████╔╝
 ██╔══██║██╔══██║██╔══██╗██╔══██╗██║   ██║██╔══██╗
 ██║  ██║██║  ██║██║  ██║██████╔╝╚██████╔╝██║  ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═╝

 Welcome to Alpine Linux minirootfs!

 Useful apk commands:
   - apk add <pkg>       : Cài gói
   - apk del <pkg>       : Gỡ gói
   - apk update          : Cập nhật index
   - apk upgrade         : Update hệ thống
   - apk search <kw>     : Tìm package
   - apk info <pkg>      : Info chi tiết

EOF

"$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="$ROOTFS_DIR" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/sh
