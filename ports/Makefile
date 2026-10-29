.RECIPEPREFIX := >
.NOTPARALLEL:

# ports/ — programas do sistema base compilados do código-fonte, estáticos com musl.
#   $(SYSROOT)  bibliotecas (só para compilar: OpenSSL, libnl)
#   $(PKGROOT)  arquivos instalados, copiados para a árvore do sistema pelo mkrootfs.sh

TOP ?= $(abspath ..)
BUILD ?= $(TOP)/build
JOBS ?= $(shell nproc 2>/dev/null || echo 1)
KHEADERS ?= $(BUILD)/kheaders
DL_DIR ?= $(BUILD)/distfiles
WORK := $(BUILD)/ports
SYSROOT ?= $(BUILD)/sysroot
PKGROOT ?= $(BUILD)/pkgroot
STAMP := $(WORK)/.stamp

TARGET_CC := musl-gcc -isystem $(KHEADERS)/include
TARGET_CFLAGS := -Os -pipe -fPIC
export PKG_CONFIG_LIBDIR := $(SYSROOT)/usr/lib/pkgconfig
export PKG_CONFIG_SYSROOT_DIR := $(SYSROOT)

OPENSSL_VERSION := 3.6.5
OPENSSL_SHA256 := a2157c2830efdec3788939b00c9b0638306d3f0bbb76dc4832ee503bb397df98
OPENSSL_URL := https://github.com/openssl/openssl/releases/download/openssl-$(OPENSSL_VERSION)/openssl-$(OPENSSL_VERSION).tar.gz

LIBNL_VERSION := 3.12.0
LIBNL_SHA256 := fc51ca7196f1a3f5fdf6ffd3864b50f4f9c02333be28be4eeca057e103c0dd18
LIBNL_URL := https://github.com/thom311/libnl/releases/download/libnl$(subst .,_,$(LIBNL_VERSION))/libnl-$(LIBNL_VERSION).tar.gz

WPA_VERSION := 2.12
WPA_SHA256 := 08e23937e16d0155e55cab2b51f51fbe10d80a1aa91c4e15442645059b737ef6
WPA_URL := https://w1.fi/releases/wpa_supplicant-$(WPA_VERSION).tar.gz

SUDO_VERSION := 1.9.17p2
SUDO_SHA256 := 4a38a1ab3adb1199257edc2a7c4a2bd714665eb605b04368843b06dada2cfcfb
SUDO_URL := https://www.sudo.ws/dist/sudo-$(SUDO_VERSION).tar.gz

E2FS_VERSION := 1.47.4
E2FS_SHA256 := fd5bf388cbdbe006a3d3b318d983b2948382440acc85a87f1e7d108653e8db0b
E2FS_URL := https://mirrors.edge.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v$(E2FS_VERSION)/e2fsprogs-$(E2FS_VERSION).tar.xz

FIRMWARE_VERSION := 20260916
FIRMWARE_SHA256 := f80dcb757a623deda62200c08e0e1a88c76fb6b54964f31b35fa74da1c90ccc5
FIRMWARE_URL := https://cdn.kernel.org/pub/linux/kernel/firmware/linux-firmware-$(FIRMWARE_VERSION).tar.xz
FIRMWARE_DIR ?= $(BUILD)/firmware
# Só o que interessa: Wi-Fi, rede cabeada, GPUs e áudio (SOF)
FIRMWARE_PATTERNS := regulatory.db* iwlwifi-* intel/iwlwifi intel/sof* intel/ibt-* \
    rtw88 rtw89 rtlwifi rtl_nic mediatek mt7601u.bin rt2870.bin rt3070.bin \
    ath9k_htc ath10k ath11k ath12k brcm cypress amdgpu i915 xe

.PHONY: all openssl libnl wpa_supplicant sudo e2fsprogs firmware clean

all: wpa_supplicant sudo e2fsprogs firmware

# fetch <url> <arquivo> <sha256> / extract <arquivo>
FETCH = sh "$(TOP)/ports/fetch.sh"

# --- OpenSSL (para o wpa_supplicant: WPA3/SAE, EAP) -------------------------------
openssl: $(STAMP)-openssl
$(STAMP)-openssl:
>$(FETCH) "$(OPENSSL_URL)" "$(DL_DIR)/openssl-$(OPENSSL_VERSION).tar.gz" "$(OPENSSL_SHA256)"
>rm -rf "$(WORK)/openssl-$(OPENSSL_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/openssl-$(OPENSSL_VERSION).tar.gz" -C "$(WORK)"
>cd "$(WORK)/openssl-$(OPENSSL_VERSION)" && \
>    CC="$(TARGET_CC)" ./Configure linux-x86_64 no-shared no-tests no-docs no-async \
>        no-module no-engine --prefix=/usr --libdir=lib --openssldir=/etc/ssl $(TARGET_CFLAGS) && \
>    $(MAKE) -j$(JOBS) build_libs && \
>    $(MAKE) DESTDIR="$(SYSROOT)" install_dev
>touch "$@"

# --- libnl (nl80211 do wpa_supplicant) ----------------------------------------------
libnl: $(STAMP)-libnl
$(STAMP)-libnl:
>$(FETCH) "$(LIBNL_URL)" "$(DL_DIR)/libnl-$(LIBNL_VERSION).tar.gz" "$(LIBNL_SHA256)"
>rm -rf "$(WORK)/libnl-$(LIBNL_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/libnl-$(LIBNL_VERSION).tar.gz" -C "$(WORK)"
>cd "$(WORK)/libnl-$(LIBNL_VERSION)" && \
>    CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS)" ./configure --prefix=/usr --sysconfdir=/etc \
>        --disable-shared --enable-static --disable-cli --disable-debug >/dev/null && \
>    $(MAKE) -j$(JOBS) && $(MAKE) DESTDIR="$(SYSROOT)" install
>touch "$@"

# --- wpa_supplicant ------------------------------------------------------------------------
wpa_supplicant: $(STAMP)-wpa_supplicant
$(STAMP)-wpa_supplicant: $(STAMP)-openssl $(STAMP)-libnl $(TOP)/ports/wpa_supplicant.config
>$(FETCH) "$(WPA_URL)" "$(DL_DIR)/wpa_supplicant-$(WPA_VERSION).tar.gz" "$(WPA_SHA256)"
>rm -rf "$(WORK)/wpa_supplicant-$(WPA_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/wpa_supplicant-$(WPA_VERSION).tar.gz" -C "$(WORK)"
>cp "$(TOP)/ports/wpa_supplicant.config" "$(WORK)/wpa_supplicant-$(WPA_VERSION)/wpa_supplicant/.config"
>$(MAKE) -C "$(WORK)/wpa_supplicant-$(WPA_VERSION)/wpa_supplicant" -j$(JOBS) \
>    CC="$(TARGET_CC)" \
>    EXTRA_CFLAGS="$(TARGET_CFLAGS) -I$(SYSROOT)/usr/include -I$(SYSROOT)/usr/include/libnl3" \
>    LDFLAGS="-static -L$(SYSROOT)/usr/lib" \
>    wpa_supplicant wpa_cli wpa_passphrase
>mkdir -p "$(PKGROOT)/usr/sbin"
>for b in wpa_supplicant wpa_cli wpa_passphrase; do \
>    install -m 755 -s "$(WORK)/wpa_supplicant-$(WPA_VERSION)/wpa_supplicant/$$b" "$(PKGROOT)/usr/sbin/$$b"; \
>done
>touch "$@"

# --- sudo ---------------------------------------------------------------------------------------
# Sem PAM: autentica pelo /etc/shadow (crypt do musl). sudoers compilado junto (estático).
sudo: $(STAMP)-sudo
$(STAMP)-sudo:
>$(FETCH) "$(SUDO_URL)" "$(DL_DIR)/sudo-$(SUDO_VERSION).tar.gz" "$(SUDO_SHA256)"
>rm -rf "$(WORK)/sudo-$(SUDO_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/sudo-$(SUDO_VERSION).tar.gz" -C "$(WORK)"
>cd "$(WORK)/sudo-$(SUDO_VERSION)" && \
>    CC="$(TARGET_CC) -static" CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="-static" ./configure \
>        --prefix=/usr --sysconfdir=/etc --libexecdir=/usr/lib \
>        --without-pam --with-shadow --enable-static-sudoers --disable-shared \
>        --disable-shared-libutil --without-sendmail --disable-nls --without-lecture \
>        --with-rundir=/run/sudo --with-vardir=/var/db/sudo --with-env-editor \
>        --with-editor=/bin/vi --with-secure-path \
>        --with-passprompt="[sudo] senha de %p: " \
>        --with-badpass-message="Senha incorreta, tente de novo." \
>        --disable-pie --enable-zlib=builtin >/dev/null && \
>    $(MAKE) -j$(JOBS) LDFLAGS="-static -all-static"
>rm -rf "$(WORK)/sudo-root"
>$(MAKE) -C "$(WORK)/sudo-$(SUDO_VERSION)" DESTDIR="$(WORK)/sudo-root" \
>    install_uid=$$(id -u) install_gid=$$(id -g) INSTALL_OWNER= install >/dev/null
>mkdir -p "$(PKGROOT)/usr/bin" "$(PKGROOT)/usr/sbin"
>install -m 4755 "$(WORK)/sudo-root/usr/bin/sudo" "$(PKGROOT)/usr/bin/sudo"
>strip "$(PKGROOT)/usr/bin/sudo"
>install -m 755 -s "$(WORK)/sudo-root/usr/sbin/visudo" "$(PKGROOT)/usr/sbin/visudo"
>ln -sf sudo "$(PKGROOT)/usr/bin/sudoedit"
>touch "$@"

# --- e2fsprogs (ext4 com journal, fsck) ----------------------------------------------------
e2fsprogs: $(STAMP)-e2fsprogs
$(STAMP)-e2fsprogs:
>$(FETCH) "$(E2FS_URL)" "$(DL_DIR)/e2fsprogs-$(E2FS_VERSION).tar.xz" "$(E2FS_SHA256)"
>rm -rf "$(WORK)/e2fsprogs-$(E2FS_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/e2fsprogs-$(E2FS_VERSION).tar.xz" -C "$(WORK)"
>cd "$(WORK)/e2fsprogs-$(E2FS_VERSION)" && \
>    CC="$(TARGET_CC) -static" CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="-static" ./configure \
>        --prefix=/usr --sbindir=/usr/sbin --sysconfdir=/etc --disable-nls --disable-fuse2fs \
>        --disable-elf-shlibs --disable-uuidd --disable-defrag --disable-debugfs --disable-imager \
>        --disable-e2initrd-helper --without-libarchive --disable-tdb >/dev/null && \
>    $(MAKE) -j$(JOBS) libs && $(MAKE) -C e2fsck -j$(JOBS) && $(MAKE) -C misc -j$(JOBS) mke2fs tune2fs && \
>    $(MAKE) -C resize -j$(JOBS)
>mkdir -p "$(PKGROOT)/usr/sbin"
>cd "$(WORK)/e2fsprogs-$(E2FS_VERSION)" && \
>    install -m 755 -s e2fsck/e2fsck misc/mke2fs misc/tune2fs resize/resize2fs "$(PKGROOT)/usr/sbin/"
>cd "$(PKGROOT)/usr/sbin" && for l in fsck.ext2 fsck.ext3 fsck.ext4; do ln -sf e2fsck $$l; done && \
>    for l in mkfs.ext2 mkfs.ext3 mkfs.ext4; do ln -sf mke2fs $$l; done && ln -sf tune2fs e2label
>touch "$@"

# --- firmware (fica na ISO, em /firmware, e é copiado para /lib/firmware na instalação) --
firmware: $(STAMP)-firmware
$(STAMP)-firmware:
>$(FETCH) "$(FIRMWARE_URL)" "$(DL_DIR)/linux-firmware-$(FIRMWARE_VERSION).tar.xz" "$(FIRMWARE_SHA256)"
>rm -rf "$(WORK)/linux-firmware-$(FIRMWARE_VERSION)" && mkdir -p "$(WORK)" && tar -xf "$(DL_DIR)/linux-firmware-$(FIRMWARE_VERSION).tar.xz" -C "$(WORK)"
>rm -rf "$(WORK)/fw-all" "$(FIRMWARE_DIR)"
>cd "$(WORK)/linux-firmware-$(FIRMWARE_VERSION)" && ./copy-firmware.sh --xz -j$(JOBS) "$(WORK)/fw-all" >/dev/null
>mkdir -p "$(FIRMWARE_DIR)"
>cd "$(WORK)/fw-all" && for p in $(FIRMWARE_PATTERNS); do \
>    for f in $$p $$p.xz; do [ -e "$$f" ] || [ -L "$$f" ] && cp -a --parents "$$f" "$(FIRMWARE_DIR)/" 2>/dev/null; done; \
>done; true
>echo "[✓] Firmware: $$(du -sh "$(FIRMWARE_DIR)" | cut -f1)"
>rm -rf "$(WORK)/fw-all" "$(WORK)/linux-firmware-$(FIRMWARE_VERSION)"
>touch "$@"

clean:
>rm -rf "$(WORK)" "$(SYSROOT)" "$(PKGROOT)" "$(FIRMWARE_DIR)"
