Welcome to Lean's git source of OpenWrt and packages
=

How to build your Openwrt firmware.
-
Note:
--
1. DO **NOT** USE **root** USER FOR COMPILING!!!

2. Users within China should prepare proxy before building.

3. Web admin panel default IP is 192.168.1.1 and default password is "password".

Let's start!
---
1. First, install Ubuntu 64bit (Ubuntu 20.04 LTS x86 is recommended).

2. Run `sudo apt-get update` in the terminal, and then run
    `
    sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
    `

3. Run `git clone https://github.com/coolsnowwolf/lede` to clone the source code, and then `cd lede` to enter the directory

4. ```bash
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   make menuconfig
   ```

5. Run `make -j8 download V=s` to download libraries and dependencies (user in China should use global proxy when possible)

6. Run `make -j1 V=s` (integer following -j is the thread count, single-thread is recommended for the first build) to start building your firmware.

This source code is promised to be compiled successfully.

You can use this source code freely, but please link this GitHub repository when redistributing. Thank you for your cooperation!
=

Rebuild:
```bash
cd lede
git pull
./scripts/feeds update -a && ./scripts/feeds install -a
make defconfig
make -j8 download
make -j$(($(nproc) + 1)) V=s
```

If reconfiguration is need:
```bash
rm -rf ./tmp && rm -rf .config
make menuconfig
make -j$(($(nproc) + 1)) V=s
```
