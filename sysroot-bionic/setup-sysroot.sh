#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PACKAGES=(
    "pool/main/g/glibc/libc6_2.27-3ubuntu1_amd64.deb"
    "pool/main/g/glibc/libc6-dev_2.27-3ubuntu1_amd64.deb"
    "pool/main/l/linux/linux-libc-dev_4.15.0-20.21_amd64.deb"
    "pool/main/g/gcc-7/libgcc-7-dev_7.3.0-16ubuntu3_amd64.deb"
    "pool/main/g/gcc-8/libgcc1_8-20180414-1ubuntu2_amd64.deb"
)

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "Downloading and extracting Ubuntu 18.04 (Bionic) packages..."

for pkg in "${PACKAGES[@]}"; do
    filename=$(basename "$pkg")
    echo "  $filename"
    curl -sL "$MIRROR/$pkg" -o "$filename"
    ar x "$filename"
    tar xf data.tar.*
    rm -f "$filename" data.tar.* control.tar.* debian-binary
done

echo "Fixing absolute symlinks..."
find . -type l | while read -r link; do
    target=$(readlink "$link")
    if [[ "$target" == /* ]]; then
        newrel=$(realpath -m --relative-to="$(dirname "$link")" ".$target")
        ln -sf "$newrel" "$link"
    fi
done

echo "Done. Sysroot ready in $(pwd)"
