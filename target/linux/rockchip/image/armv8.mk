# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2020 Tobias Maedel

define Device/friendlyarm_nanopi-r2s
  DEVICE_VENDOR := FriendlyARM
  DEVICE_MODEL := NanoPi R2S
  SOC := rk3328
  UBOOT_DEVICE_NAME := nanopi-r2s-rk3328
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
  DEVICE_PACKAGES := kmod-usb-net-rtl8152
endef
TARGET_DEVICES += friendlyarm_nanopi-r2s

define Device/xunlong_orangepi-r1-plus
  DEVICE_VENDOR := Xunlong
  DEVICE_MODEL := Orange Pi R1 Plus
  SOC := rk3328
  UBOOT_DEVICE_NAME := orangepi-r1-plus-rk3328
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
  DEVICE_PACKAGES := kmod-usb-net-rtl8152
endef
TARGET_DEVICES += xunlong_orangepi-r1-plus

define Device/friendlyarm_nanopi-r4s
  DEVICE_VENDOR := FriendlyARM
  DEVICE_MODEL := NanoPi R4S
  SOC := rk3399
  UBOOT_DEVICE_NAME := nanopi-r4s-rk3399
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
  DEVICE_PACKAGES := kmod-r8169 -urngd
endef
TARGET_DEVICES += friendlyarm_nanopi-r4s

define Device/friendlyarm_nanopi-r5s
  DEVICE_VENDOR := FriendlyARM
  DEVICE_MODEL := NanoPi R5S
  SOC := rk3328
  DEVICE_PACKAGES := kmod-r8125
  DEVICE_DTS = rockchip/rk3328-nanopi-r2s
endef
TARGET_DEVICES += friendlyarm_nanopi-r5s

define Device/pine64_rockpro64
  DEVICE_VENDOR := Pine64
  DEVICE_MODEL := RockPro64
  SOC := rk3399
  UBOOT_DEVICE_NAME := rockpro64-rk3399
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
  DEVICE_PACKAGES := -urngd
endef
TARGET_DEVICES += pine64_rockpro64

define Device/firefly_roc-cc
  DEVICE_VENDOR := Firefly
  DEVICE_MODEL := ROC-RK3328-CC
  SOC := rk3328
  UBOOT_DEVICE_NAME := roc-cc-rk3328
  SUPPORTED_DEVICES := firefly,roc-rk3328-cc
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
endef
TARGET_DEVICES += firefly_roc-cc

define Device/friendlyarm_nanopi-neo3
  DEVICE_VENDOR := FriendlyARM
  DEVICE_MODEL := NanoPi NEO3
  SOC := rk3328
  UBOOT_DEVICE_NAME := nanopi-r2s-rk3328
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
endef
TARGET_DEVICES += friendlyarm_nanopi-neo3

define Device/pine64_quartz64-a
  DEVICE_VENDOR := Pine64
  DEVICE_MODEL := QUARTZ64
  SOC := rk3566
  SUPPORTED_DEVICES := pine64,quartz64-a
  UBOOT_DEVICE_NAME := quartz64-a-rk3566
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
endef
TARGET_DEVICES += pine64_quartz64-a

define Device/radxa_rock-3a
  DEVICE_VENDOR := Radxa
  DEVICE_MODEL := ROCK3 Model A
  SOC := rk3568
  SUPPORTED_DEVICES := radxa,rock3a
  UBOOT_DEVICE_NAME := rock-3a-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
endef
TARGET_DEVICES += radxa_rock-3a

define Device/radxa_rock-pi-4
  DEVICE_VENDOR := Radxa
  DEVICE_MODEL := ROCK Pi 4
  DEVICE_DTS := rockchip/rk3399-rock-pi-4b
  SOC := rk3399
  SUPPORTED_DEVICES := radxa,rockpi4b
  UBOOT_DEVICE_NAME := rock-pi-4-rk3399
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
  DEVICE_PACKAGES := \
	brcmfmac-firmware-43456-sdio \
	brcmfmac-firmware-43456-sdio-rockpi-4 \
	kmod-brcmfmac wpad-basic-wolfssl
endef
TARGET_DEVICES += radxa_rock-pi-4

define Device/rockchip_bpi-r2-pro
  DEVICE_VENDOR := Rockchip
  DEVICE_MODEL := Bananapi-R2 Pro
  SOC := rk3568
  SUPPORTED_DEVICES := rockchip,rk3568-bpi-r2pro
  UBOOT_DEVICE_NAME := bpi-r2-pro-rk3568
  IMAGE/sysupgrade.img.gz := boot-common | boot-script | pine64-bin | gzip | append-metadata
endef
TARGET_DEVICES += rockchip_bpi-r2-pro
