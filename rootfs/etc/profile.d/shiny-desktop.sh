# Ambiente do desktop KDE (perfil do Nix em /nix/var/nix/profiles/shiny-desktop)
_P=/nix/var/nix/profiles/shiny-desktop
if [ -e "$_P" ]; then
    export PATH="$PATH:$_P/bin"
    export XDG_DATA_DIRS="$HOME/.nix-profile/share:$_P/share:/usr/share"
    export XDG_CONFIG_DIRS="/etc/xdg:$_P/etc/xdg"
    export QT_PLUGIN_PATH="$_P/lib/qt-6/plugins"
    export QML2_IMPORT_PATH="$_P/lib/qt-6/qml"
    export QML_IMPORT_PATH="$QML2_IMPORT_PATH"
    export GIO_EXTRA_MODULES="$_P/lib/gio/modules"
    export GTK_PATH="$_P/lib/gtk-3.0:$_P/lib/gtk-4.0"
    export XCURSOR_PATH="$HOME/.icons:$_P/share/icons"
    export FONTCONFIG_FILE=/etc/fonts/fonts.conf
    export LOCALE_ARCHIVE="$_P/lib/locale/locale-archive"
    export LANG="${LANG:-pt_BR.UTF-8}"
    export XDG_MENU_PREFIX=plasma-
    export __EGL_VENDOR_LIBRARY_DIRS="$_P/share/glvnd/egl_vendor.d"
    export LIBGL_DRIVERS_PATH="$_P/lib/dri"
    export GBM_BACKENDS_PATH="$_P/lib/gbm"
    export VK_ICD_FILENAMES="$(ls "$_P"/share/vulkan/icd.d/*.json 2>/dev/null | tr '\n' ':')"
    # o elogind cria /run/user/<uid> ao abrir a sessão
    if [ -z "${XDG_RUNTIME_DIR:-}" ] && [ -d "/run/user/$(id -u)" ]; then
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    fi

    # Abre o Plasma sozinho ao entrar no tty1 (desligue em /etc/rc.conf: desktop_autostart="NO")
    if [ -z "${SHINY_SESSION:-}" ] && [ "$(id -u)" -ne 0 ] && [ "$(tty)" = /dev/tty1 ] &&
       [ -z "${WAYLAND_DISPLAY:-}" ] &&
       grep -q '^desktop_autostart="YES"' /etc/rc.conf 2>/dev/null; then
        shiny-session
        printf '\n  O KDE foi fechado. Para abrir de novo: shiny-session\n\n'
    fi
fi
unset _P
