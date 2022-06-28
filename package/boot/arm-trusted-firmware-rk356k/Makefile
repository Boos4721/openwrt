#
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=arm-trusted-firmware-rk356x
PKG_RELEASE:=1.1
PKG_SOURCE_DATE:=2021-06-01
PKG_SOURCE_VERSION:=7d631e0d5b2d373b54d4533580d08fb9bd2eaad4
PKG_SOURCE_PROTO:=git
PKG_FLAGS:=nonshared
PKG_MIRROR_HASH:=f11aad3ed05079dadbdfe81f3272d610de3e4f92c4b6c1f027565afb427a223a
PKG_SOURCE_URL:=https://github.com/rockchip-linux/rkbin.git

include $(INCLUDE_DIR)/package.mk

define Package/arm-trusted-firmware-rk356x
    SECTION:=boot
    CATEGORY:=Boot Loaders
    TITLE:=ARM Trusted Firmware for RK356X
    DEPENDS:=@TARGET_rockchip_armv8
endef

define Build/Compile
endef

define Build/InstallDev
	$(INSTALL_DIR) $(STAGING_DIR_IMAGE)
	$(CP) $(PKG_BUILD_DIR)/bin/rk35/rk3568_bl31_v1.24.elf $(PKG_BUILD_DIR)/bl31.elf
	$(CP) $(PKG_BUILD_DIR)/bl31.elf $(STAGING_DIR_IMAGE)/
	$(CP) $(PKG_BUILD_DIR)/bin/rk35/rk3568_ddr_1560MHz_v1.08.bin $(PKG_BUILD_DIR)/ram_init.bin
	$(CP) $(PKG_BUILD_DIR)/ram_init.bin $(STAGING_DIR_IMAGE)/
endef

define Package/arm-trusted-firmware-rk356x/install
endef

$(eval $(call BuildPackage,arm-trusted-firmware-rk356x))
