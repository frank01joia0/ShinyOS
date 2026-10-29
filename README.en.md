# ShinyOS ✦

### [Português](README.md) • English

ShinyOS is an independent Linux distribution built from scratch (Linux kernel + BusyBox + its own userland), inspired by the BSD philosophy: a small base system configured through `/etc/rc.conf` and scripts in `/etc/rc.d`.

ShinyOS is the continuation of **LunairOS**, a discontinued distro. Thanks to its original author for the foundation. 💜

## Current release

**ShinyOS 0.2.0 "Glimmer"**

## What works

- Linux 6.18 LTS kernel, NVMe/SATA/USB/virtio, Intel/AMD GPUs, audio
- **KDE Plasma 6 desktop** (Wayland) with Dolphin, Konsole, Kate, Firefox and the skeuomorphic
  Oxygen theme available — installed through Nix with `sudo shiny-desktop install` or in the installer
- **Wi-Fi**: Intel, Realtek, MediaTek, Atheros and Broadcom; connect with the `wifi` command
- **sudo** for administrator users (`wheel` group)
- **Live** boot with a welcome menu (automatic login)
- **Guided installer** (`shiny-install`): disk, user, password, keyboard and time zone through menus;
  installs GRUB for **UEFI and BIOS** and registers a "ShinyOS" UEFI boot entry
- **Packages via Nix**: `pkg install htop` — 100k+ programs from nixpkgs, per-user
- `shiny` settings menu: users, passwords, network, keyboard, time zone, services, packages
- Automatic wired networking via DHCP, DNS, clock sync (ntpd)
- BSD-style services: `/etc/rc.conf`, `service -l`, `service network restart`
- `shinyfetch` (the old `lunafetch` still works as an alias)

## Limitations

- No graphical login screen: log in on `tty1` with your user and Plasma starts automatically
- No NVIDIA driver (Intel, AMD and virtual GPUs only)
- Enterprise Wi-Fi (eduroam) still needs manual configuration
- The KDE desktop needs internet to install (~3 GB)

## Dependencies

```sh
make install-deps-arch     # Arch / CachyOS
make install-deps-debian   # Debian / Ubuntu
```

## Build

```sh
make release
```

This downloads and builds the kernel and BusyBox, builds the userland, assembles the system and produces `build/ShinyOS-Glimmer-0.2.0.iso`. No root required.

## Test in QEMU

```sh
make run           # live ISO, BIOS
make run-uefi      # live ISO, UEFI
make run-install   # ISO + 8 GB virtual disk, to try shiny-install
make run-disk      # boot the virtual disk after installing
```

## Project structure

```text
configs/       - kernel and BusyBox configs (+ ShinyOS fragments)
kernel/        - Linux kernel build
busybox/       - BusyBox build (static, musl)
userland/      - ShinyOS programs (shinyfetch, shiny-install)
rootfs/        - system files (/etc, rc.d, scripts)
initramfs/     - boot /init (live mode and installed system)
iso/           - GRUB and ISO generation
scripts/       - build scripts
build/         - generated files
```

## Roadmap

1. ✅ Usable, installable terminal system (UEFI and BIOS)
2. ✅ Package manager (`pkg`, on top of Nix)
3. ✅ Wi-Fi and sudo
4. ✅ KDE Plasma (via Nix)
5. Graphical login screen, Bluetooth, eduroam from the menu
6. ShinyOS's own skeuomorphic theme

## License

ShinyOS is licensed under the GNU General Public License v3.0 (GPLv3).

## Third-party software

- Linux kernel (GPLv2)
- BusyBox (GPLv2)
- GRUB (GPLv3)
- musl libc (MIT)
- Nix (LGPL-2.1)
- sudo (ISC), wpa_supplicant (BSD), OpenSSL (Apache-2.0), libnl (LGPL-2.1)
- linux-firmware (various licenses, see WHENCE)
- KDE Plasma and applications (GPL/LGPL, downloaded from nixpkgs)
