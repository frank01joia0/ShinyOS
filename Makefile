.RECIPEPREFIX := >
.NOTPARALLEL:

TOP := $(CURDIR)

PROJECT ?= ShinyOS
VERSION ?= 0.2.0
CODENAME ?= Glimmer
KERNEL_VERSION ?= 6.18.59
BUSYBOX_VERSION ?= 1.38.0
NIX_VERSION ?= 2.35.3
NIX_SHA256 ?= 6ce3ce3703fdc241b560cba401c5d338042122fe5b1a81e07bf1a623f259eba0
NIX_TARBALL ?= $(BUILD)/distfiles/nix-$(NIX_VERSION)-x86_64-linux.tar.xz

BUILD ?= $(TOP)/build
JOBS ?= $(shell nproc 2>/dev/null || echo 1)

USERLAND_DEST ?= $(BUILD)/userland
BUSYBOX ?= $(BUILD)/busybox/busybox
KERNEL_IMAGE ?= $(BUILD)/kernel/bzImage
MODULES_DIR ?= $(BUILD)/kernel/modules
KHEADERS ?= $(BUILD)/kheaders
GEN_INIT_CPIO ?= $(BUILD)/tools/gen_init_cpio
EFI_IMAGE ?= $(BUILD)/BOOTX64.EFI
INITRAMFS_IMAGE ?= $(BUILD)/initramfs.cpio.gz
ISO_IMAGE ?= $(BUILD)/$(PROJECT)-$(CODENAME)-$(VERSION).iso

# QEMU
QEMU ?= qemu-system-x86_64
QEMU_MEM ?= 1G
QEMU_DISK ?= $(BUILD)/disk.img
QEMU_DISK_SIZE ?= 20G
OVMF_CODE ?= $(firstword $(wildcard /usr/share/edk2/x64/OVMF_CODE.4m.fd /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/ovmf/x64/OVMF_CODE.fd))
OVMF_VARS ?= $(firstword $(wildcard /usr/share/edk2/x64/OVMF_VARS.4m.fd /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd /usr/share/ovmf/x64/OVMF_VARS.fd))
QEMU_ACCEL := $(shell [ -w /dev/kvm ] && echo "-enable-kvm -cpu host" || echo "-cpu qemu64")
QEMU_FLAGS ?= -machine q35 $(QEMU_ACCEL) -smp 2 -m $(QEMU_MEM) -serial stdio -no-reboot \
              -nic user,model=virtio-net-pci
QEMU_UEFI = -drive if=pflash,format=raw,readonly=on,file=$(OVMF_CODE) \
            -drive if=pflash,format=raw,file=$(BUILD)/OVMF_VARS.fd

export

.PHONY: all world release kernel buildkernel buildbusybox busybox builduserland userland efi nix ports \
        buildworld initramfs iso run qemu run-uefi run-install run-disk check \
        install-deps-arch install-deps-debian clean cleanuserland cleankernel cleaninitramfs \
        cleaniso distclean help

all: release

world: clean release

release: check iso

kernel buildkernel:
>$(MAKE) -C kernel TOP="$(TOP)" all

busybox buildbusybox: kernel
>$(MAKE) -C busybox TOP="$(TOP)" all

userland builduserland:
>$(MAKE) -C userland TOP="$(TOP)" DESTDIR="$(USERLAND_DEST)" all install

efi:
>$(MAKE) -C iso TOP="$(TOP)" efi

# Nix (gerenciador de pacotes): o tarball oficial vai dentro da imagem e é
# instalado pelo shiny-install ou pelo "pkg setup", sem precisar de internet
nix: $(NIX_TARBALL)

$(NIX_TARBALL):
>mkdir -p "$(dir $@)"
>wget -c -O "$@.part" "https://releases.nixos.org/nix/nix-$(NIX_VERSION)/nix-$(NIX_VERSION)-x86_64-linux.tar.xz"
>echo "$(NIX_SHA256)  $@.part" | sha256sum -c -
>mv "$@.part" "$@"

# Programas do sistema base compilados do código-fonte (sudo, wpa_supplicant) + firmware
ports: busybox
>$(MAKE) -C ports TOP="$(TOP)" all

initramfs buildworld: kernel busybox userland efi nix ports
>$(MAKE) -C initramfs TOP="$(TOP)" all

iso: initramfs
>$(MAKE) -C iso TOP="$(TOP)" all

# --- testes no QEMU -------------------------------------------------------------
# run          ISO live, BIOS
# run-uefi     ISO live, UEFI (OVMF)
# run-install  ISO live, UEFI + disco virtual em $(QEMU_DISK) para testar o shiny-install
# run-disk     dá boot no disco virtual já instalado
run qemu:
>@test -f "$(ISO_IMAGE)" || $(MAKE) release
>$(QEMU) $(QEMU_FLAGS) -cdrom "$(ISO_IMAGE)"

$(BUILD)/OVMF_VARS.fd:
>@test -n "$(OVMF_VARS)" || { echo "[!] OVMF não encontrado (Arch: pacman -S edk2-ovmf)"; exit 1; }
>mkdir -p "$(BUILD)"
>cp "$(OVMF_VARS)" "$@"

$(QEMU_DISK):
>truncate -s $(QEMU_DISK_SIZE) "$@"

run-uefi: $(BUILD)/OVMF_VARS.fd
>@test -f "$(ISO_IMAGE)" || $(MAKE) release
>$(QEMU) $(QEMU_FLAGS) $(QEMU_UEFI) -cdrom "$(ISO_IMAGE)"

run-install: $(BUILD)/OVMF_VARS.fd $(QEMU_DISK)
>@test -f "$(ISO_IMAGE)" || $(MAKE) release
>$(QEMU) $(QEMU_FLAGS) $(QEMU_UEFI) -drive file="$(QEMU_DISK)",format=raw,if=virtio -cdrom "$(ISO_IMAGE)" -boot d

run-disk: $(BUILD)/OVMF_VARS.fd
>$(QEMU) $(QEMU_FLAGS) $(QEMU_UEFI) -drive file="$(QEMU_DISK)",format=raw,if=virtio

# --- dependências ---------------------------------------------------------------------
check:
>@missing=""; \
>for cmd in make gcc wget tar xz bzip2 bc bison flex perl cpio gzip xorriso mformat file; do \
>    command -v $$cmd >/dev/null 2>&1 || missing="$$missing $$cmd"; \
>done; \
>command -v grub-mkrescue >/dev/null 2>&1 || command -v grub2-mkrescue >/dev/null 2>&1 || missing="$$missing grub"; \
>if [ -n "$$missing" ]; then \
>    echo "[!] Faltando ferramentas:$$missing"; \
>    echo "    Rode: make install-deps-arch  (ou install-deps-debian)"; \
>    exit 1; \
>fi; \
>command -v musl-gcc >/dev/null 2>&1 || echo "[i] musl-gcc ausente: BusyBox e userland serão compilados com glibc estática"; \
>command -v loadkeys >/dev/null 2>&1 || echo "[i] loadkeys (kbd) ausente: a imagem não terá mapas de teclado"; \
>echo "[✓] Ferramentas principais encontradas"

install-deps-arch:
>sudo pacman -S --needed base-devel wget bc bison flex perl openssl libelf pahole cpio \
>    xorriso mtools grub musl kbd file qemu-desktop edk2-ovmf

install-deps-debian:
>sudo apt update
>sudo apt install -y build-essential wget xz-utils bzip2 bc bison flex perl libssl-dev libelf-dev \
>    dwarves cpio gzip xorriso mtools grub-common grub-pc-bin grub-efi-amd64-bin \
>    qemu-system-x86 qemu-utils ovmf file musl-tools kbd

# --- limpeza -------------------------------------------------------------------------
cleanuserland:
>$(MAKE) -C userland TOP="$(TOP)" DESTDIR="$(USERLAND_DEST)" clean || true
>rm -rf "$(USERLAND_DEST)"

clean: cleanuserland cleaninitramfs cleaniso

cleankernel:
>$(MAKE) -C kernel TOP="$(TOP)" clean

cleaninitramfs:
>$(MAKE) -C initramfs TOP="$(TOP)" clean

cleaniso:
>$(MAKE) -C iso TOP="$(TOP)" clean

distclean:
>rm -rf "$(BUILD)"

help:
>@echo "Comandos:"
>@echo "  make release        - compila tudo e gera a ISO (build/*.iso)"
>@echo "  make kernel         - só o kernel"
>@echo "  make busybox        - só o BusyBox"
>@echo "  make userland       - só os programas da ShinyOS (shinyfetch, shiny-install)"
>@echo "  make initramfs      - monta o sistema (rootfs + initramfs)"
>@echo "  make run            - testa a ISO no QEMU (BIOS)"
>@echo "  make run-uefi       - testa a ISO no QEMU (UEFI)"
>@echo "  make run-install    - ISO + disco virtual, para testar o shiny-install"
>@echo "  make run-disk       - dá boot no disco virtual instalado"
>@echo "  make install-deps-arch / install-deps-debian"
>@echo "  make clean          - limpa userland/initramfs/iso"
>@echo "  make distclean      - apaga build/ (inclusive downloads)"
