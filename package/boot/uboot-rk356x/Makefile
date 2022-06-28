#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_VERSION:=2022.07-rc5
PKG_RELEASE:=$(AUTORELEASE)

PKG_HASH:=7d5e7afc7e940e21d60ce207e77e4d63b5bd0597ce46b913e5e4601f1a30df56


include $(INCLUDE_DIR)/u-boot.mk
include $(INCLUDE_DIR)/package.mk

define U-Boot/Default
  BUILD_TARGET:=rockchip
  UENV:=default
  HIDDEN:=1
endef


# RK35xx boards

define U-Boot/bpi-r2-pro-rk3568
  BUILD_SUBTARGET:=armv8
  NAME:=BPI-R2-PRO
  BUILD_DEVICES:= \
    rockchip_bpi-r2-pro
  DEPENDS:=+PACKAGE_u-boot-bpi-r2-pro-rk3568:arm-trusted-firmware-rk356x
endef

define U-Boot/quartz64-a-rk3566
  BUILD_SUBTARGET:=armv8
  NAME:=QUARTZ64
  BUILD_DEVICES:= \
    pine64_quartz64-a
  DEPENDS:=+PACKAGE_u-boot-quartz64-a-rk3566:arm-trusted-firmware-rk356x
endef

define U-Boot/evb-rk3568
  BUILD_SUBTARGET:=armv8
  NAME:=EVB1
  BUILD_DEVICES:= \
    rockchip_evb
  DEPENDS:=+PACKAGE_u-boot-evb-rk3568:arm-trusted-firmware-rk356x
  DEFAULT := y
endef

define U-Boot/nanopi-r5s-rk3568
  BUILD_SUBTARGET:=armv8
  NAME:=NANOPI-R5S
  BUILD_DEVICES:= \
    friendlyelec_nanopi-r5s
  DEPENDS:=+PACKAGE_u-boot-nanopi-r5s-rk3568:arm-trusted-firmware-rk356x
endef

define U-Boot/rock-3a-rk3568
  BUILD_SUBTARGET:=armv8
  NAME:=ROCK-3A
  BUILD_DEVICES:= \
    radxa_rock-3a
  DEPENDS:=+PACKAGE_u-boot-rock-3a-rk3568:arm-trusted-firmware-rk356x
endef

UBOOT_TARGETS := \
  bpi-r2-pro-rk3568 \
  evb-rk3568 \
  nanopi-r5s-rk3568 \
  quartz64-a-rk3566 \
  rock-3a-rk3568


UBOOT_CONFIGURE_VARS += USE_PRIVATE_LIBGCC=yes



define Build/Configure
	$(call Build/Configure/U-Boot)
	$(SED) 's#CONFIG_MKIMAGE_DTC_PATH=.*#CONFIG_MKIMAGE_DTC_PATH="$(PKG_BUILD_DIR)/scripts/dtc/dtc"#g' $(PKG_BUILD_DIR)/.config
	echo 'CONFIG_IDENT_STRING=" OpenWrt"' >> $(PKG_BUILD_DIR)/.config
	$(CP) $(STAGING_DIR_IMAGE)/bl31.elf $(PKG_BUILD_DIR)/bl31.elf
	$(CP) $(STAGING_DIR_IMAGE)/ram_init.bin $(PKG_BUILD_DIR)/ram_init.bin
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(PKG_BUILD_DIR)/idbloader.img $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-idbloader.img
	$(CP) $(PKG_BUILD_DIR)/u-boot.itb $(STAGING_DIR_IMAGE)/$(BUILD_VARIANT)-u-boot.itb
endef

define Package/u-boot/install/default
endef

$(eval $(call BuildPackage/U-Boot))
