#!/usr/bin/env bash

# OpenWrt CI Builder
# Copyright (C) 2021 @Boos4721(Telegram and Github)
# Default Settings

export ARCH=amd64
export SUBARCH=amd64
export FORCE_UNSAFE_CONFIGURE=1
export FORCE=1
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime


SETUP() {
git config --global user.email 3.1415926535boos@gmail.com
git config --global user.name Boos4721
}

CLONE() {
git clone https://github.com/Boos4721/OpenWrt-Packages package/Boos --depth=1
wget -O .config https://gitlab.com/Boos4721//openwrt/-/raw/master/.config
wget -O package/base-files/files/etc/profile https://gitlab.com/Boos4721/openwrt/-/raw/master/profile
wget -O package/base-files/files/etc/banner https://gitlab.com/Boos4721/openwrt/-/raw/master/banner
wget -O package/kernel/mac80211/files/lib/wifi/mac80211.sh https://gitlab.com/Boos4721/openwrt/-/raw/master/mac80211.sh
./scripts/feeds update -a -f
./scripts/feeds install -a -f
}

MAIN() {
Version_File="package/lean/default-settings/files/zzz-default-settings"
Old_Version="$(egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" ${Version_File})"
sed -i "s?By?By Boos4721 ?g" package/base-files/files/etc/banner
sed -i "s?Openwrt?Openwrt ${Openwrt_Version}?g" package/base-files/files/etc/banner
sed -i '/profile/d' package/base-files/files/lib/upgrade/keep.d/base-files-essential
sed -i "s?${Old_Version}?${Old_Version} By Boos4721 ?g" ${Version_File}
}


BUILD() {
make defconfig
BUILD_START=$(date +"%s")
echo " ${Old_Version} Starting first build..."
make download -j$(nproc)
make -j$(nproc) || make -j$(nproc) V=s
BUILD_END=$(date +"%s")
}

SETUP
CLONE
MAIN
BUILD

DIFF=$(($BUILD_END - $BUILD_START))
echo "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds"
