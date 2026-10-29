.RECIPEPREFIX := >

TOP ?= ..
BUILD ?= $(TOP)/build
PROJECT ?= ShinyOS
VERSION ?= 0.2.0
CODENAME ?= Glimmer

ISO_ROOT ?= $(BUILD)/iso
KERNEL_IMAGE ?= $(BUILD)/kernel/bzImage
INITRAMFS_IMAGE ?= $(BUILD)/initramfs.cpio.gz
ISO_IMAGE ?= $(BUILD)/$(PROJECT)-$(CODENAME)-$(VERSION).iso
EFI_IMAGE ?= $(BUILD)/BOOTX64.EFI
GRUB_CFG ?= $(TOP)/iso/boot/grub/grub.cfg
FIRMWARE_DIR ?= $(BUILD)/firmware
ISO_LABEL ?= SHINYOS_$(subst .,_,$(VERSION))

GRUB_MKRESCUE ?= $(shell command -v grub-mkrescue || command -v grub2-mkrescue)
GRUB_MKSTANDALONE ?= $(shell command -v grub-mkstandalone || command -v grub2-mkstandalone)
GRUB_MKIMAGE ?= $(shell command -v grub-mkimage || command -v grub2-mkimage)
GRUB_PC_DIR ?= $(firstword $(wildcard /usr/lib/grub/i386-pc /usr/lib/grub2/i386-pc /usr/share/grub2/i386-pc))
BIOS_DIR ?= $(BUILD)/bios

.PHONY: all efi bios list clean FORCE

all: $(ISO_IMAGE)

# GRUB que o shiny-install grava no disco: EFI autossuficiente + BIOS (MBR)
efi: $(EFI_IMAGE) bios

# core.img vai nos setores 1..2047 do disco; o boot.img (446 bytes) na MBR.
# Com o core.img começando no setor 1, os valores padrão do boot.img e da
# blocklist do diskboot.img já apontam certo, sem precisar do grub-bios-setup.
# "(,msdos1)" = partição 1 do disco por onde a BIOS deu boot.
bios: $(BIOS_DIR)/core.img

$(BIOS_DIR)/core.img:
>@test -n "$(GRUB_MKIMAGE)" && test -f "$(GRUB_PC_DIR)/boot.img" || { echo "[!] GRUB i386-pc não encontrado"; exit 1; }
>mkdir -p "$(BIOS_DIR)"
>"$(GRUB_MKIMAGE)" -O i386-pc -o "$@" -p "(,msdos1)/EFI/BOOT" \
>    biosdisk part_msdos fat ext2 normal linux configfile echo search regexp all_video
>cp "$(GRUB_PC_DIR)/boot.img" "$(BIOS_DIR)/boot.img"
>@size=$$(stat -c %s "$@"); test $$size -lt 1040000 || { echo "[!] core.img grande demais ($$size)"; exit 1; }
>echo "[✓] $@"

$(EFI_IMAGE): $(TOP)/iso/efi-embed.cfg
>@test -n "$(GRUB_MKSTANDALONE)" || { echo "[!] grub-mkstandalone não encontrado (instale o GRUB)"; exit 1; }
>"$(GRUB_MKSTANDALONE)" -O x86_64-efi -o "$@" \
>    --modules="part_msdos part_gpt fat ext2 regexp configfile linux normal echo all_video gfxterm search" \
>    --locales="" --themes="" --fonts="" \
>    "boot/grub/grub.cfg=$(TOP)/iso/efi-embed.cfg"
>echo "[✓] $@"

$(ISO_IMAGE): FORCE
>echo "[*] Montando ISO $(PROJECT) $(VERSION) \"$(CODENAME)\"..."
>@test -f "$(KERNEL_IMAGE)" || { echo "[!] Kernel não encontrado: $(KERNEL_IMAGE)"; exit 1; }
>@test -f "$(INITRAMFS_IMAGE)" || { echo "[!] Initramfs não encontrada: $(INITRAMFS_IMAGE)"; exit 1; }
>@test -n "$(GRUB_MKRESCUE)" || { echo "[!] grub-mkrescue não encontrado"; exit 1; }
>rm -rf "$(ISO_ROOT)"
>mkdir -p "$(ISO_ROOT)/boot/grub"
>cp "$(KERNEL_IMAGE)" "$(ISO_ROOT)/boot/vmlinuz"
>cp "$(INITRAMFS_IMAGE)" "$(ISO_ROOT)/boot/initramfs.img"
>@if [ -d "$(FIRMWARE_DIR)" ]; then cp -a "$(FIRMWARE_DIR)" "$(ISO_ROOT)/firmware"; else echo "[!] sem firmware na ISO"; fi
>sed 's/@PRETTY@/$(PROJECT) $(VERSION) "$(CODENAME)"/g' "$(GRUB_CFG)" > "$(ISO_ROOT)/boot/grub/grub.cfg"
>"$(GRUB_MKRESCUE)" -o "$@" "$(ISO_ROOT)" -- -volid "$(ISO_LABEL)"
>echo "[✓] ISO pronta: $@"

list: $(ISO_IMAGE)
>xorriso -indev "$(ISO_IMAGE)" -find / -type f -print

clean:
>rm -rf "$(ISO_ROOT)" "$(ISO_IMAGE)" "$(EFI_IMAGE)" "$(BIOS_DIR)"

FORCE:
