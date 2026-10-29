.RECIPEPREFIX := >
.NOTPARALLEL:

TOP ?= $(abspath ..)
BUILD ?= $(TOP)/build
BUSYBOX_VERSION ?= 1.38.0
BUSYBOX_URL ?= https://busybox.net/downloads/busybox-$(BUSYBOX_VERSION).tar.bz2
JOBS ?= $(shell nproc 2>/dev/null || echo 1)

# musl gera um binário estático pequeno; sem ele, cai para glibc estática
BUSYBOX_CC ?= $(shell command -v musl-gcc >/dev/null 2>&1 && echo musl-gcc || echo gcc)
KHEADERS ?= $(BUILD)/kheaders

DL_DIR ?= $(BUILD)/distfiles
SRC_DIR ?= $(BUILD)/busybox-$(BUSYBOX_VERSION)
OUT_DIR ?= $(BUILD)/busybox
TARBALL ?= $(DL_DIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
FRAGMENT ?= $(TOP)/configs/busybox.fragment
CONFIG_FILE ?= $(TOP)/configs/busybox.config
OUT ?= $(OUT_DIR)/busybox

BB_CC := $(BUSYBOX_CC)$(if $(filter musl-gcc,$(BUSYBOX_CC)), -isystem $(KHEADERS)/include)

.PHONY: all config menuconfig list clean distclean

all: $(OUT)

$(TARBALL):
>mkdir -p "$(DL_DIR)"
>wget -c -O "$@.part" "$(BUSYBOX_URL)"
>mv "$@.part" "$@"

$(SRC_DIR)/Makefile: $(TARBALL)
>rm -rf "$(SRC_DIR)"
>tar -xf "$(TARBALL)" -C "$(BUILD)"
>touch "$@"

$(SRC_DIR)/.config: $(FRAGMENT) $(TOP)/scripts/apply-fragment.sh $(SRC_DIR)/Makefile
>echo "[*] Configurando BusyBox (defconfig + fragmento)..."
>$(MAKE) -C "$(SRC_DIR)" defconfig >/dev/null
>sh "$(TOP)/scripts/apply-fragment.sh" "$@" "$(FRAGMENT)"
>yes "" | $(MAKE) -C "$(SRC_DIR)" oldconfig >/dev/null
>cp "$@" "$(CONFIG_FILE)"

config: $(SRC_DIR)/.config

menuconfig: $(SRC_DIR)/.config
>$(MAKE) -C "$(SRC_DIR)" menuconfig
>cp "$(SRC_DIR)/.config" "$(CONFIG_FILE)"

$(OUT): $(SRC_DIR)/.config
>@if [ "$(BUSYBOX_CC)" = musl-gcc ] && [ ! -f "$(KHEADERS)/include/linux/version.h" ]; then \
>    echo "[!] Headers do kernel não encontrados em $(KHEADERS) (rode: make -C kernel headers)"; exit 1; \
>fi
>echo "[*] Compilando BusyBox $(BUSYBOX_VERSION) com $(BUSYBOX_CC)..."
>$(MAKE) -C "$(SRC_DIR)" -j"$(JOBS)" CC="$(BB_CC)" busybox
>mkdir -p "$(OUT_DIR)"
>cp "$(SRC_DIR)/busybox" "$@"
>file "$@"
>echo "[✓] BusyBox pronto: $$("$@" --list | wc -l) applets"

list: $(OUT)
>"$(OUT)" --list

clean:
>test ! -d "$(SRC_DIR)" || $(MAKE) -C "$(SRC_DIR)" clean
>rm -rf "$(OUT_DIR)"

distclean:
>rm -rf "$(SRC_DIR)" "$(OUT_DIR)"
