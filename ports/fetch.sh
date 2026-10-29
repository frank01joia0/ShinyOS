#!/bin/sh
# fetch.sh <url> <destino> <sha256> — baixa (se preciso) e confere o hash
set -eu
url=$1 dest=$2 sum=$3
mkdir -p "$(dirname "$dest")"
if [ ! -f "$dest" ]; then
    wget -c -O "$dest.part" "$url"
    mv "$dest.part" "$dest"
fi
echo "$sum  $dest" | sha256sum -c --quiet - || { echo "[!] hash errado: $dest" >&2; exit 1; }
