#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PACKAGES=(
    "pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb"
    "pool/main/g/glibc/libc6-dev_2.35-0ubuntu3_amd64.deb"
    "pool/main/l/linux/linux-libc-dev_5.15.0-25.25_amd64.deb"
    "pool/main/g/gcc-11/libgcc-11-dev_11.2.0-19ubuntu1_amd64.deb"
    "pool/main/g/gcc-12/libgcc-s1_12-20220319-1ubuntu1_amd64.deb"
)

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "Downloading and extracting Ubuntu 22.04 (Jammy) packages..."

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
