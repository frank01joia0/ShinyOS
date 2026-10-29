# Desktop KDE Plasma da ShinyOS, montado com o Nix.
# Instalado em /nix/var/nix/profiles/shiny-desktop pelo comando: shiny-desktop install
#
# O nixpkgs é fixado numa versão estável, então todo mundo recebe exatamente
# os mesmos pacotes. Para atualizar o desktop, troque a URL abaixo.
let
  nixpkgs = builtins.fetchTarball
    "https://releases.nixos.org/nixos/26.05/nixos-26.05.13050.08d3a97586f6/nixexprs.tar.xz";
  pkgs = import nixpkgs {
    config.allowUnfree = false;
  };
  kde = pkgs.kdePackages;
in
pkgs.buildEnv {
  name = "shiny-desktop";
  ignoreCollisions = true;
  pathsToLink = [ "/" ];
  extraOutputsToInstall = [ "out" "bin" "lib" "man" ];

  paths = with pkgs; [
    # Infraestrutura que o NixOS normalmente forneceria
    dbus
    elogind       # logind sem systemd: sessões, acesso à GPU/entrada para o KWin
    shadow        # login com PAM (registra a sessão no elogind)
    eudev
    mesa
    libglvnd
    vulkan-loader
    xwayland
    fontconfig
    shared-mime-info
    desktop-file-utils
    hicolor-icon-theme
    xdg-utils
    xdg-user-dirs
    linux-pam
    glibcLocales
    pipewire
    wireplumber
    libinput

    # Fontes
    noto-fonts
    noto-fonts-color-emoji
    dejavu_fonts
    liberation_ttf

    # Plasma
    kde.plasma-workspace
    kde.plasma-desktop
    kde.kwin
    kde.kscreen
    kde.kscreenlocker
    kde.kdecoration
    kde.kglobalacceld
    kde.kactivitymanagerd
    kde.plasma-integration
    kde.plasma-pa
    kde.plasma-workspace-wallpapers
    kde.plasma5support
    kde.libplasma
    kde.milou
    kde.kmenuedit
    kde.systemsettings
    kde.kinfocenter
    kde.kde-cli-tools
    kde.kde-gtk-config
    kde.ksystemstats
    kde.libksysguard
    kde.plasma-systemmonitor
    kde.powerdevil
    kde.xdg-desktop-portal-kde
    xdg-desktop-portal
    kde.qtwayland
    kde.qtsvg
    kde.qtimageformats
    kde.qtmultimedia
    kde.kirigami
    kde.qqc2-desktop-style
    kde.qqc2-breeze-style
    kde.kio
    kde.kio-extras
    kde.kservice

    # Visual: Breeze padrão + Oxygen (o tema esqueumórfico, como na LunairOS)
    kde.breeze
    kde.breeze-icons
    kde.breeze-gtk
    kde.oxygen
    kde.oxygen-icons
    kde.oxygen-sounds
    kde.ocean-sound-theme

    # Aplicativos
    kde.dolphin
    kde.konsole
    kde.kate
    kde.ark
    kde.gwenview
    kde.okular
    kde.spectacle
    kde.kcalc
    firefox
  ];
}
