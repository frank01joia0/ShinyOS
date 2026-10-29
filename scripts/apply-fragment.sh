#!/bin/sh
# apply-fragment.sh <.config> <fragmento>
# Aplica as linhas CONFIG_X=... / "# CONFIG_X is not set" / CONFIG_X=n
# do fragmento sobre um .config de Kconfig (kernel ou BusyBox).
set -eu

config=$1
fragment=$2
tmp=$config.fragtmp

cp "$config" "$tmp"
grep -E '^(CONFIG_[A-Za-z0-9_]+=|# CONFIG_[A-Za-z0-9_]+ is not set)' "$fragment" |
while IFS= read -r line; do
    case $line in
        "# CONFIG_"*) sym=${line#\# }; sym=${sym%% *}; new="# $sym is not set" ;;
        *=n)          sym=${line%%=*};  new="# $sym is not set" ;;
        *)            sym=${line%%=*};  new=$line ;;
    esac
    grep -v -E "^($sym=|# $sym is not set)" "$tmp" > "$tmp.2" || true
    printf '%s\n' "$new" >> "$tmp.2"
    mv "$tmp.2" "$tmp"
done
mv "$tmp" "$config"
