include $(TOPDIR)/rules.mk

ARCH:=aarch64
BOARD:=ipq807x
BOARDNAME:=Qualcomm Atheros IPQ807x
FEATURES:=squashfs ramdisk fpu nand source-only
KERNELNAME:=Image dtbs
CPU_TYPE:=cortex-a53
SUBTARGETS:=generic

KERNEL_PATCHVER:=5.10
KERNEL_TESTING_PATCHVER:=5.15

include $(INCLUDE_DIR)/target.mk
DEFAULT_PACKAGES += \
	kmod-leds-gpio kmod-gpio-button-hotplug \
	ath11k-firmware-ipq8074 kmod-ath11k-ahb ath11k-board-ipq8074 \
	wpad-openssl kmod-qca-nss-dp kmod-qca-nss-drv kmod-qca-nss-drv-pppoe kmod-qca-nss-ecm  kmod-qca-nss-drv-bridge-mgr qca-nss-gmac nss-firmware-ipq8074 \
	zram-swap autocore-arm htop luci-app-cpufreq luci-app-eqos uboot-envtools \

$(eval $(call BuildTarget))
