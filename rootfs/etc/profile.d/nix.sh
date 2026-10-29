# Ativa o Nix (pacotes instalados com "pkg install") quando ele estiver instalado
if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi
