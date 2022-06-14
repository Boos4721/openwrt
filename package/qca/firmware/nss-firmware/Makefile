#
# Copyright (C) 2021 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=nss-firmware
PKG_SOURCE_DATE:=2022-05-16
PKG_SOURCE_VERSION:=20c9a9b7e0ea2935b0a54f112104e433009312ca
PKG_MIRROR_HASH:=376b3605776f75bccb1da2b30dd522cc22d3f6b17dff6c954dd9b7222418d6c6
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/quic/qca-sdk-nss-fw.git

PKG_LICENSE_FILES:=LICENSE.md

PKG_MAINTAINER:=Robert Marko <robimarko@gmail.com>

include $(INCLUDE_DIR)/package.mk

VERSION_PATH=$(PKG_BUILD_DIR)/QCA_Networking.SPF_11.5.0/CS

define Package/nss-firmware-default
  SECTION:=firmware
  CATEGORY:=Firmware
  URL:=$(PKG_SOURCE_URL)
  DEPENDS:=@(TARGET_ipq807x||TARGET_ipq60xx)
endef

define Package/nss-firmware-ipq6018
$(Package/nss-firmware-default)
  TITLE:=NSS firmware for IPQ6018 devices
  NSS_ARCHIVE:=$(VERSION_PATH)/IPQ6018.ATH.11.5.0/BIN-NSS.FW.12.0.r1-002-CP.R.tar.bz2
endef

define Package/nss-firmware-ipq8074
$(Package/nss-firmware-default)
  TITLE:=NSS firmware for IPQ8074 devices
  NSS_ARCHIVE:=$(VERSION_PATH)/IPQ8074.ATH.11.5.0/BIN-NSS.FW.12.0.r1-002-HK.R.tar.bz2
endef

define Build/Compile

endef

define Package/nss-firmware-ipq6018/install
	mkdir -p $(PKG_BUILD_DIR)/IPQ6018
	$(TAR) -C $(PKG_BUILD_DIR)/IPQ6018 -xf $(NSS_ARCHIVE) --strip-components=1
	$(INSTALL_DIR) $(1)/lib/firmware/
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/IPQ6018/retail_router0.bin \
		$(1)/lib/firmware/qca-nss0-retail.bin
endef

define Package/nss-firmware-ipq8074/install
	mkdir -p $(PKG_BUILD_DIR)/IPQ8074
	$(TAR) -C $(PKG_BUILD_DIR)/IPQ8074 -xf $(NSS_ARCHIVE) --strip-components=1
	$(INSTALL_DIR) $(1)/lib/firmware/
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/IPQ8074/retail_router0.bin \
		$(1)/lib/firmware/qca-nss0-retail.bin
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/IPQ8074/retail_router1.bin \
		$(1)/lib/firmware/qca-nss1-retail.bin
endef

$(eval $(call BuildPackage,nss-firmware-ipq6018))
$(eval $(call BuildPackage,nss-firmware-ipq8074))
