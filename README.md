# ShinyOS ✦

### Português • [English](README.en.md)

ShinyOS é uma distribuição Linux independente, construída do zero (kernel Linux + BusyBox + userland próprio), com inspiração na filosofia BSD: um sistema base pequeno, configurado por `/etc/rc.conf` e scripts em `/etc/rc.d`.

A ShinyOS é a continuação da **LunairOS**, distro que foi descontinuada. Obrigado à autora original pela base. 💜

## Atual lançamento

**ShinyOS 0.2.0 "Glimmer"**

## O que funciona

- Kernel Linux 6.18 LTS, NVMe/SATA/USB/virtio, GPUs Intel/AMD, áudio
- **Desktop KDE Plasma 6** (Wayland), com Dolphin, Konsole, Kate, Firefox e o tema
  esqueumórfico Oxygen disponível — instalado pelo Nix com `sudo shiny-desktop install`
  ou direto no instalador
- **Wi-Fi**: Intel, Realtek, MediaTek, Atheros e Broadcom; conecte com o comando `wifi`
- **sudo** para os usuários administradores (grupo `wheel`)
- Boot **live** com menu de boas-vindas (entra sozinho, sem senha)
- **Instalador guiado** (`shiny-install`): escolhe disco, usuário, senha, teclado e fuso por menus;
  instala o GRUB para **UEFI e BIOS** e registra a entrada "ShinyOS" no menu de boot do UEFI
- **Pacotes via Nix**: `pkg install htop` — acesso a mais de 100 mil programas do nixpkgs,
  cada usuário com seus próprios pacotes
- Menu de configurações `shiny`: usuários, senhas, rede, teclado, fuso, serviços, pacotes
- Rede cabeada automática via DHCP, DNS, sincronia de relógio (ntpd)
- Serviços estilo BSD: `/etc/rc.conf`, `service -l`, `service network restart`
- `shinyfetch` (o antigo `lunafetch` também funciona como apelido)

## Limitações

- Não há tela de login gráfica: entre no `tty1` com seu usuário e o Plasma abre sozinho
- Placas NVIDIA não têm driver (só Intel, AMD e virtuais)
- Redes Wi-Fi corporativas (eduroam) ainda são configuradas à mão
- O desktop KDE precisa de internet para instalar (~3 GB)

## Dependências

### Arch / CachyOS

```sh
make install-deps-arch
```

### Debian / Ubuntu

```sh
make install-deps-debian
```

## Compilar

```sh
make release
```

Isso baixa e compila o kernel e o BusyBox, compila o userland, monta o sistema e gera `build/ShinyOS-Glimmer-0.2.0.iso`. Não precisa de root.

Gravar num pendrive (cuidado com o `of=`!):

```sh
sudo dd if=build/ShinyOS-Glimmer-0.2.0.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

## Testar no QEMU

```sh
make run           # ISO live, BIOS
make run-uefi      # ISO live, UEFI
make run-install   # ISO + disco virtual de 8 GB, para testar o shiny-install
make run-disk      # dá boot no disco virtual depois de instalar
```

## Usando o sistema

| Tarefa | Comando |
| --- | --- |
| Menu de configurações | `shiny` |
| Conectar ao Wi-Fi | `wifi` |
| Instalar o KDE Plasma | `sudo shiny-desktop install` |
| Abrir o KDE manualmente | `shiny-session` |
| Comando como administrador | `sudo comando` |
| Instalar programas | `pkg install htop` |
| Procurar / listar / remover | `pkg search editor` · `pkg list` · `pkg remove htop` |
| Informações do sistema | `shinyfetch` |
| Instalar no disco (modo live) | `shiny-install` |
| Serviços | `service -l` · `service network restart` |
| Configuração manual | `vi /etc/rc.conf` |
| Desligar / reiniciar | `poweroff` / `reboot` |

## Estrutura do projeto

```text
configs/       - configs do kernel e do BusyBox (+ fragmentos da ShinyOS)
kernel/        - build do kernel Linux
busybox/       - build do BusyBox (estático, musl)
userland/      - programas da ShinyOS (shinyfetch, shiny-install, shiny-efiboot)
ports/         - receitas do sistema base: sudo, wpa_supplicant (+OpenSSL, libnl), firmware
rootfs/        - arquivos do sistema (/etc, rc.d, scripts)
initramfs/     - /init de boot (modo live e sistema instalado)
iso/           - GRUB e geração da ISO
scripts/       - scripts de build
build/         - arquivos gerados
```

## Roadmap

1. ✅ Sistema de terminal usável, instalável (UEFI e BIOS)
2. ✅ Gerenciador de pacotes (`pkg`, sobre o Nix)
3. ✅ Wi-Fi e sudo
4. ✅ KDE Plasma (via Nix)
5. Tela de login gráfica, Bluetooth, eduroam pelo menu
6. Tema esqueumórfico próprio da ShinyOS

## Licença

ShinyOS é licenciada sob a GNU General Public License v3.0 (GPLv3).

## Software de terceiros

- Kernel Linux (GPLv2)
- BusyBox (GPLv2)
- GRUB (GPLv3)
- musl libc (MIT)
- Nix (LGPL-2.1)
- sudo (ISC), wpa_supplicant (BSD), OpenSSL (Apache-2.0), libnl (LGPL-2.1)
- linux-firmware (várias licenças, veja WHENCE)
- KDE Plasma e aplicativos (GPL/LGPL, baixados do nixpkgs)
