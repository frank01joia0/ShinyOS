# ShinyOS ✦

**Português** • [English](README.en.md)

Uma distro Linux independente, feita do zero, com KDE Plasma e cara de sistema amigável.

![ShinyOS com KDE Plasma](docs/screenshot.png)

A ShinyOS não é baseada em nenhuma outra distro. Ela junta:

- o kernel Linux e o BusyBox, compilados aqui mesmo;
- um sistema base pequeno no estilo BSD (`/etc/rc.conf` + `/etc/rc.d`);
- o **Nix** para instalar programas e o desktop **KDE Plasma 6**.

Ela continua a **LunairOS**, a distro de uma amiga que foi descontinuada. Obrigado pela base. 💜

**Versão atual:** 0.2.0 "Glimmer"

---

## Destaques

- 🖥️ **KDE Plasma 6** (Wayland) com Dolphin, Konsole, Kate, Okular, Gwenview, Firefox e o tema Oxygen
- 📶 **Wi-Fi** com o comando `wifi`, com WPA2 e WPA3. Funciona com placas Intel, Realtek, MediaTek, Atheros e Broadcom
- 🔐 **sudo** para quem é administrador (grupo `wheel`)
- 📦 **Mais de 100 mil programas** pelo Nix: `pkg install htop`
- 💿 **Instalador guiado em português**:
  - escolhe o disco, o usuário, o teclado e o fuso por menus;
  - funciona em computadores **UEFI e BIOS**.
- ⚙️ **Menu `shiny`** para Wi-Fi, usuários, senhas, rede, teclado, fuso, serviços e pacotes
- 🛟 **Disco em ext4**, verificado sozinho a cada boot
- 🌙 **Modo live**: experimente a distro pelo pendrive sem instalar nada

## Instalando

1. Baixe ou compile a ISO (veja abaixo).
2. Grave num pendrive. **Confira o `/dev/sdX`**: o disco escolhido é apagado.

   ```sh
   sudo dd if=ShinyOS-Glimmer-0.2.0.iso of=/dev/sdX bs=4M status=progress conv=fsync
   ```

3. Dê boot pelo pendrive. O menu de boas-vindas abre sozinho.
4. Se precisar de internet, escolha **Conectar ao Wi-Fi** (no cabo, a conexão é automática).
5. Escolha **Instalar a ShinyOS no computador** e responda às perguntas.
6. Reinicie e entre com seu usuário. O KDE Plasma abre sozinho.

**Requisitos:**
- 64 bits (x86_64);
- 2 GB de RAM (4 GB recomendados);
- 20 GB de disco;
- internet para instalar o KDE (uns 1,7 GB de download).

## Usando

| Quero… | Comando |
| --- | --- |
| Abrir o menu de configurações | `shiny` |
| Conectar ao Wi-Fi | `wifi` |
| Instalar um programa | `pkg install vlc` |
| Procurar, listar ou remover programas | `pkg search editor` · `pkg list` · `pkg remove vlc` |
| Rodar algo como administrador | `sudo comando` |
| Instalar o KDE depois | `sudo shiny-desktop install` |
| Abrir o KDE à mão | `shiny-session` |
| Ver informações do sistema | `shinyfetch` |
| Ver e controlar serviços | `service -l` · `sudo service wifi restart` |
| Desligar ou reiniciar | `poweroff` · `reboot` |

As configurações do sistema ficam em `/etc/rc.conf`, no estilo dos BSDs:

```sh
hostname="brilho"
keymap="br-abnt2"
timezone="America/Sao_Paulo"
wifi_enable="YES"
desktop_autostart="YES"
```

## Limitações conhecidas

- Não há tela de login gráfica: o Plasma abre quando você entra no `tty1`.
- Placas de vídeo **NVIDIA** ainda não têm driver. Intel, AMD e máquinas virtuais funcionam.
- Redes Wi-Fi corporativas (eduroam) precisam ser configuradas à mão.
- Bluetooth ainda não funciona.
- Até agora, só foi testada em máquinas virtuais. Relatos de hardware de verdade são muito bem-vindos!

---

## Compilando

Não precisa de root. Primeiro instale as dependências:

```sh
make install-deps-arch     # Arch, CachyOS, Manjaro
make install-deps-debian   # Debian, Ubuntu, Mint
```

Depois:

```sh
make release
```

Isso baixa e compila o kernel, o BusyBox, o sudo, o wpa_supplicant e o resto do sistema base. O resultado é `build/ShinyOS-Glimmer-0.2.0.iso`. Todos os downloads têm o SHA-256 conferido. A primeira compilação demora bastante; as seguintes são rápidas.

### Testando no QEMU

```sh
make run            # modo live, BIOS
make run-uefi       # modo live, UEFI
make run-install    # live + disco virtual de 20 GB, para testar o instalador
make run-disk       # dá boot no disco virtual já instalado
```

Para o KDE, dê mais memória para a VM: `make run-disk QEMU_MEM=2G`.

### Como o projeto é organizado

```text
configs/      configuração do kernel e do BusyBox (+ fragmentos da ShinyOS)
kernel/       compilação do kernel Linux
busybox/      compilação do BusyBox (estático, com musl)
ports/        sudo, wpa_supplicant (+OpenSSL, libnl), e2fsprogs e firmware
userland/     programas da ShinyOS: shinyfetch, shiny-install, shiny-efiboot
rootfs/       arquivos do sistema: /etc, rc.d, menus, Nix e o desktop
initramfs/    o /init de boot (modo live e sistema instalado)
iso/          GRUB e geração da ISO
scripts/      scripts auxiliares de build
```

## Roadmap

- [x] Sistema de terminal instalável (UEFI e BIOS)
- [x] Gerenciador de pacotes (`pkg`, sobre o Nix)
- [x] Wi-Fi e sudo
- [x] KDE Plasma 6
- [ ] Testes em hardware real
- [ ] Tela de login gráfica
- [ ] Bluetooth e eduroam pelo menu
- [ ] Driver NVIDIA
- [ ] Tema esqueumórfico próprio da ShinyOS

## Licença

ShinyOS é software livre, sob a [GNU GPL v3.0](LICENSE).

Programas de terceiros incluídos ou baixados:

- Linux e BusyBox (GPLv2)
- GRUB (GPLv3)
- musl (MIT)
- Nix (LGPL-2.1)
- sudo (ISC)
- wpa_supplicant (BSD)
- OpenSSL (Apache-2.0)
- libnl (LGPL-2.1)
- e2fsprogs (GPLv2)
- linux-firmware (várias licenças; veja o arquivo `WHENCE`)
- KDE Plasma e aplicativos (GPL/LGPL, vindos do nixpkgs)
