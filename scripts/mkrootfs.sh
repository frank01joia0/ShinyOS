#!/bin/sh
# mkrootfs.sh — monta a árvore do sistema e gera as imagens de initramfs.
#
#   $BUILD/rootfs            árvore completa do sistema (staging)
#   $BUILD/initrd-boot.img   initramfs mínima que monta o disco (sistema instalado)
#   $INITRAMFS_IMAGE         initramfs live (sistema inteiro, roda na RAM)
#
# Não precisa de root: os donos/permissões/devices são definidos na lista
# do gen_init_cpio, não no sistema de arquivos do host.
set -eu

: "${TOP:?}" "${BUILD:?}" "${BUSYBOX:?}" "${USERLAND_DEST:?}" "${KERNEL_IMAGE:?}"
: "${INITRAMFS_IMAGE:?}" "${VERSION:?}" "${CODENAME:?}"
MODULES_DIR=${MODULES_DIR:-$BUILD/kernel/modules}
GEN_INIT_CPIO=${GEN_INIT_CPIO:-$BUILD/tools/gen_init_cpio}
EFI_IMAGE=${EFI_IMAGE:-$BUILD/BOOTX64.EFI}
BIOS_DIR=${BIOS_DIR:-$BUILD/bios}
KEYMAPS=${KEYMAPS:-br-abnt2 us pt-latin1 es de fr uk}

STAGE=$BUILD/rootfs
BOOTSTAGE=$BUILD/bootfs
BOOT_INITRD=$BUILD/initrd-boot.img

log() { echo "[ROOTFS] $*"; }

# cpio_list <dir>: lista para o gen_init_cpio, tudo pertencendo a root
cpio_list() {
    (
        cd "$1"
        echo "nod /dev/console 0600 0 0 c 5 1"
        echo "nod /dev/null 0666 0 0 c 1 3"
        find . -mindepth 1 | sort | while IFS= read -r p; do
            p=${p#.}
            mode=$(stat -c %a ".$p")
            case $p in
                /etc/shadow) mode=600 ;;
                /etc/sudoers) mode=440 ;;
                /etc/sudoers.d|/var/db/sudo) mode=750 ;;
                # su/passwd/ping para usuários comuns; com FEATURE_SUID o BusyBox
                # descarta o root nos applets que não precisam dele
                /bin/busybox) mode=4755 ;;
                /root)       mode=700 ;;
                /tmp|/var/tmp) mode=1777 ;;
            esac
            if [ -L ".$p" ]; then
                echo "slink $p $(readlink ".$p") 0777 0 0"
            elif [ -d ".$p" ]; then
                echo "dir $p $mode 0 0"
            elif [ -f ".$p" ]; then
                echo "file $p $(pwd)$p $mode 0 0"
            fi
        done
    )
}

install_busybox() {
    mkdir -p "$1/bin" "$1/sbin" "$1/usr/bin" "$1/usr/sbin"
    cp "$BUSYBOX" "$1/bin/busybox"
    chmod 755 "$1/bin/busybox"
    "$BUSYBOX" --list-full | while read -r applet; do
        [ "$applet" = bin/busybox ] && continue
        [ -e "$1/$applet" ] || ln -s /bin/busybox "$1/$applet"
    done
}

# --- sistema completo ---------------------------------------------------------
log "Montando árvore em $STAGE"
rm -rf "$STAGE"
mkdir -p "$STAGE"
for d in bin sbin lib usr/bin usr/sbin usr/lib/shinyos usr/share/keymaps \
         dev proc sys run tmp mnt media root home opt srv \
         var/log var/spool/cron/crontabs var/tmp var/lib; do
    mkdir -p "$STAGE/$d"
done
ln -s /run "$STAGE/var/run"
cp -a "$TOP/rootfs/." "$STAGE/"

codename_lc=$(echo "$CODENAME" | tr 'A-Z' 'a-z')
for f in etc/os-release etc/issue; do
    sed -i -e "s/@VERSION@/$VERSION/g" -e "s/@CODENAME@/$CODENAME/g" \
           -e "s/@CODENAME_LC@/$codename_lc/g" "$STAGE/$f"
done
# \e não é interpretado pelo getty: grava o ESC de verdade
sed -i "s/\\\\e/$(printf '\033')/g" "$STAGE/etc/issue"

install_busybox "$STAGE"

PKGROOT=${PKGROOT:-$BUILD/pkgroot}
if [ -d "$PKGROOT" ]; then
    log "Copiando programas de ports/ (sudo, wpa_supplicant, e2fsprogs)"
    # tira os links do BusyBox com o mesmo nome (o cp seguiria o link e
    # sobrescreveria o próprio /bin/busybox), em qualquer diretório do PATH
    (cd "$PKGROOT" && find . ! -type d) | while IFS= read -r f; do
        n=${f##*/}
        for d in bin sbin usr/bin usr/sbin; do
            [ -L "$STAGE/$d/$n" ] && rm -f "$STAGE/$d/$n"
        done
        rm -f "$STAGE/${f#./}"
    done
    cp -a "$PKGROOT/." "$STAGE/"
    mkdir -p "$STAGE/var/db/sudo"
fi

if [ -d "$USERLAND_DEST" ]; then
    log "Copiando userland"
    cp -a "$USERLAND_DEST/." "$STAGE/"
fi

if [ -d "$MODULES_DIR/lib/modules" ]; then
    log "Copiando módulos do kernel"
    cp -a "$MODULES_DIR/lib/modules" "$STAGE/lib/"
    for kv in "$STAGE"/lib/modules/*; do
        rm -f "$kv/build" "$kv/source"
        "$BUSYBOX" depmod -b "$STAGE" "${kv##*/}" 2>/dev/null || true
    done
fi

if command -v loadkeys >/dev/null 2>&1; then
    for km in $KEYMAPS; do
        loadkeys -b "$km" > "$STAGE/usr/share/keymaps/$km.bmap" 2>/dev/null \
            && log "Teclado: $km" \
            || { rm -f "$STAGE/usr/share/keymaps/$km.bmap"; log "[!] loadkeys não conhece $km"; }
    done
else
    log "[!] loadkeys (kbd) ausente no host: sem mapas de teclado"
fi

# --- initramfs mínima do sistema instalado ---------------------------------------
log "Gerando $BOOT_INITRD"
rm -rf "$BOOTSTAGE"
mkdir -p "$BOOTSTAGE/dev" "$BOOTSTAGE/proc" "$BOOTSTAGE/sys" "$BOOTSTAGE/newroot"
install_busybox "$BOOTSTAGE"
# fsck do disco antes de montar (o sistema instalado usa ext4)
if [ -x "$PKGROOT/usr/sbin/e2fsck" ]; then
    rm -f "$BOOTSTAGE/sbin/fsck"
    cp "$PKGROOT/usr/sbin/e2fsck" "$BOOTSTAGE/sbin/e2fsck"
fi
cp "$TOP/initramfs/init" "$BOOTSTAGE/init"
chmod 755 "$BOOTSTAGE/init"
cpio_list "$BOOTSTAGE" > "$BUILD/initrd-boot.list"
"$GEN_INIT_CPIO" "$BUILD/initrd-boot.list" | gzip -9 > "$BOOT_INITRD"

# Arquivos que o shiny-install copia para a partição EFI
cp "$KERNEL_IMAGE" "$STAGE/usr/lib/shinyos/vmlinuz"
cp "$BOOT_INITRD" "$STAGE/usr/lib/shinyos/initrd.img"
if [ -f "$EFI_IMAGE" ]; then
    cp "$EFI_IMAGE" "$STAGE/usr/lib/shinyos/BOOTX64.EFI"
else
    log "[!] $EFI_IMAGE ausente: o shiny-install não vai funcionar"
fi
if [ -f "$BIOS_DIR/core.img" ]; then
    mkdir -p "$STAGE/usr/lib/shinyos/bios"
    cp "$BIOS_DIR/core.img" "$BIOS_DIR/boot.img" "$STAGE/usr/lib/shinyos/bios/"
else
    log "[!] GRUB BIOS ausente: o shiny-install só vai instalar para UEFI"
fi
if [ -n "${NIX_TARBALL:-}" ] && [ -f "$NIX_TARBALL" ]; then
    log "Incluindo Nix $NIX_VERSION"
    mkdir -p "$STAGE/usr/lib/shinyos/nix"
    cp "$NIX_TARBALL" "$STAGE/usr/lib/shinyos/nix/"
    echo "$NIX_VERSION" > "$STAGE/usr/lib/shinyos/nix/VERSION"
else
    log "[!] tarball do Nix ausente: o pkg não vai funcionar"
fi

# --- initramfs live -------------------------------------------------------------------
cp "$TOP/initramfs/init" "$STAGE/init"
chmod 755 "$STAGE/init"
log "Gerando $INITRAMFS_IMAGE"
cpio_list "$STAGE" > "$BUILD/initramfs.list"
"$GEN_INIT_CPIO" "$BUILD/initramfs.list" | gzip -9 > "$INITRAMFS_IMAGE"
log "Pronto: $(du -h "$INITRAMFS_IMAGE" | cut -f1) (live), $(du -h "$BOOT_INITRD" | cut -f1) (boot)"
