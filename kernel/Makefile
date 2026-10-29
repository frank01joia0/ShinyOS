.RECIPEPREFIX := >
.NOTPARALLEL:

TOP ?= ..
BUILD ?= $(TOP)/build
KERNEL_VERSION ?= 6.18.59
KERNEL_URL ?= https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$(KERNEL_VERSION).tar.xz
JOBS ?= $(shell nproc 2>/dev/null || echo 1)

DL_DIR ?= $(BUILD)/distfiles
KBUILD ?= $(BUILD)/kernel
CONFIG ?= $(TOP)/configs/kernel.config
FRAGMENT ?= $(TOP)/configs/kernel.fragment
KSRC ?= $(KBUILD)/linux-$(KERNEL_VERSION)
TARBALL ?= $(DL_DIR)/linux-$(KERNEL_VERSION).tar.xz
KERNEL_IMAGE ?= $(KBUILD)/bzImage
MODULES_DIR ?= $(KBUILD)/modules
KHEADERS ?= $(BUILD)/kheaders
GEN_INIT_CPIO ?= $(BUILD)/tools/gen_init_cpio

.PHONY: all config menuconfig headers tools clean distclean mrproper

all: $(KERNEL_IMAGE) $(MODULES_DIR)/.stamp headers tools

$(TARBALL):
>mkdir -p "$(DL_DIR)"
>echo "[*] Baixando Linux $(KERNEL_VERSION)..."
>wget -c -O "$@.part" "$(KERNEL_URL)"
>mv "$@.part" "$@"

$(KSRC)/Makefile: $(TARBALL)
>echo "[*] Extraindo kernel em $(KBUILD)..."
>rm -rf "$(KSRC)"
>mkdir -p "$(KBUILD)"
>tar -C "$(KBUILD)" -xf "$(TARBALL)"
>touch "$@"

$(KSRC)/.config: $(CONFIG) $(FRAGMENT) $(TOP)/scripts/apply-fragment.sh $(KSRC)/Makefile
>echo "[*] Aplicando config do kernel..."
>cp "$(CONFIG)" "$@"
>sh "$(TOP)/scripts/apply-fragment.sh" "$@" "$(FRAGMENT)"
>$(MAKE) -C "$(KSRC)" olddefconfig

config: $(KSRC)/.config

menuconfig: $(KSRC)/.config
>$(MAKE) -C "$(KSRC)" menuconfig
>cp "$(KSRC)/.config" "$(CONFIG)"
>echo "[✓] Config salva em $(CONFIG) (o fragmento continua sendo aplicado por cima)"

$(KERNEL_IMAGE): $(KSRC)/.config
>echo "[*] Compilando kernel com $(JOBS) job(s)..."
>$(MAKE) -C "$(KSRC)" -j"$(JOBS)" bzImage modules
>mkdir -p "$(KBUILD)"
>cp "$(KSRC)/arch/x86/boot/bzImage" "$@"
>echo "[✓] Kernel pronto: $@"

$(MODULES_DIR)/.stamp: $(KERNEL_IMAGE)
>rm -rf "$(MODULES_DIR)"
>mkdir -p "$(MODULES_DIR)"
>$(MAKE) -C "$(KSRC)" INSTALL_MOD_PATH="$(MODULES_DIR)" INSTALL_MOD_STRIP=1 DEPMOD=/bin/true modules_install
>touch "$@"

# Headers da API do kernel, usados pelo musl-gcc para compilar o BusyBox
headers: $(KHEADERS)/.stamp

$(KHEADERS)/.stamp: $(KSRC)/Makefile
>rm -rf "$(KHEADERS)"
>$(MAKE) -C "$(KSRC)" INSTALL_HDR_PATH="$(KHEADERS)" headers_install
>touch "$@"

# gen_init_cpio monta a initramfs com donos/devices corretos sem precisar de root
tools: $(GEN_INIT_CPIO)

$(GEN_INIT_CPIO): $(KSRC)/Makefile
>mkdir -p "$(dir $@)"
>$(CC) -O2 -o "$@" "$(KSRC)/usr/gen_init_cpio.c"

clean:
>@if [ -d "$(KSRC)" ]; then $(MAKE) -C "$(KSRC)" clean || true; fi
>rm -rf "$(KERNEL_IMAGE)" "$(MODULES_DIR)"

mrproper:
>@if [ -d "$(KSRC)" ]; then $(MAKE) -C "$(KSRC)" mrproper || true; fi
>rm -rf "$(KERNEL_IMAGE)" "$(MODULES_DIR)"

distclean:
>rm -rf "$(KBUILD)" "$(KHEADERS)" "$(GEN_INIT_CPIO)"
