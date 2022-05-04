include $(TOPDIR)/rules.mk

ARCH:=aarch64
BOARD:=ipq807x
BOARDNAME:=Qualcomm Atheros IPQ807x
FEATURES:=squashfs ramdisk fpu nand emmc
KERNELNAME:=Image dtbs
CPU_TYPE:=cortex-a53
SUBTARGETS:=generic

KERNEL_PATCHVER:=5.15

include $(INCLUDE_DIR)/target.mk
DEFAULT_PACKAGES += \
	kmod-usb3 kmod-usb-dwc3 kmod-usb-dwc3-qcom \
	kmod-leds-gpio kmod-gpio-button-hotplug \
	ath11k-firmware-ipq8074 kmod-ath11k-ahb kmod-qca-nss-drv kmod-qca-nss-dp kmod-qca-nss-drv-pppoe kmod-qca-nss-drv-bridge-mgr nss-firmware-ipq8074 \
	wpad-openssl uboot-envtools zram-swap autocore-arm htop luci-app-cpufreq \

$(eval $(call BuildTarget))
