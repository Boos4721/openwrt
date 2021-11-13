include $(TOPDIR)/rules.mk

PKG_NAME:=qca-nss-crypto
PKG_RELEASE:=$(AUTORELEASE)

PKG_SOURCE_URL:=https://source.codeaurora.org/quic/qsdk/oss/lklm/nss-crypto
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2021-03-20
PKG_SOURCE_VERSION:=2271a3a66f7e8284d42a9e787ddec6f24a1d2e15
PKG_MIRROR_HASH:=afd2b746779bf9abb72dfb58c755acf54d1cb51085b879013dd0edf9ba98d3c9

PKG_BUILD_PARALLEL:=1

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

ifeq ($(CONFIG_TARGET_BOARD), "ipq807x")
    SOC="ipq807x_64"
else ifeq ($(CONFIG_TARGET_BOARD), "ipq60xx")
    SOC="ipq60xx_64"
endif

# v1.0 is for Akronite
# v2.0 is for Hawkeye/Cypress/Maple
ifneq (, $(findstring $(CONFIG_TARGET_BOARD), "ipq807x" "ipq60xx"))
NSS_CRYPTO_DIR:=v2.0
else
NSS_CRYPTO_DIR:=v1.0
endif

define KernelPackage/qca-nss-crypto
  SECTION:=kernel
  CATEGORY:=Kernel modules
  SUBMENU:=Network Devices
  DEPENDS:=@(TARGET_ipq807x||TARGET_ipq60xx) +kmod-qca-nss-drv +nss-eip-firmware
  TITLE:=Kernel driver for NSS crypto driver
  FILES:=$(PKG_BUILD_DIR)/$(NSS_CRYPTO_DIR)/src/qca-nss-crypto.ko \
	 $(PKG_BUILD_DIR)/$(NSS_CRYPTO_DIR)/tool/qca-nss-crypto-tool.ko
  AUTOLOAD:=$(call AutoLoad,52,qca-nss-crypto)
endef

define KernelPackage/qca-nss-crypto/Description
This package contains a NSS crypto driver for QCA chipset
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include/qca-nss-crypto
	$(CP) $(PKG_BUILD_DIR)/$(NSS_CRYPTO_DIR)/include/* $(1)/usr/include/qca-nss-crypto
endef

EXTRA_CFLAGS+= \
	-DCONFIG_NSS_DEBUG_LEVEL=4 \
	-I$(STAGING_DIR)/usr/include/qca-nss-crypto \
	-I$(STAGING_DIR)/usr/include/qca-nss-drv \
	-I$(PKG_BUILD_DIR)/$(NSS_CRYPTO_DIR)/include \
	-I$(PKG_BUILD_DIR)/$(NSS_CRYPTO_DIR)/src

define Build/Compile
	+$(MAKE) -C "$(LINUX_DIR)" \
		CC="$(TARGET_CC)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		ARCH="$(LINUX_KARCH)" \
		M="$(PKG_BUILD_DIR)" \
		EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
		NSS_CRYPTO_DIR=$(NSS_CRYPTO_DIR) \
		SoC=$(SOC) \
		$(KERNEL_MAKE_FLAGS) \
		$(PKG_JOBS) \
		modules
endef

$(eval $(call KernelPackage,qca-nss-crypto))
