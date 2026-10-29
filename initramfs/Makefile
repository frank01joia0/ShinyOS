.RECIPEPREFIX := >

TOP ?= ..
BUILD ?= $(TOP)/build

.PHONY: all list clean

all:
>sh "$(TOP)/scripts/mkrootfs.sh"

list:
>gzip -dc "$(INITRAMFS_IMAGE)" | cpio -t

clean:
>rm -rf "$(BUILD)/rootfs" "$(BUILD)/bootfs" "$(BUILD)"/initramfs.list "$(BUILD)"/initrd-boot.* "$(INITRAMFS_IMAGE)"
