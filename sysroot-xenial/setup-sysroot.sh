#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PACKAGES=(
    "pool/main/g/glibc/libc6_2.23-0ubuntu3_amd64.deb"
    "pool/main/g/glibc/libc6-dev_2.23-0ubuntu3_amd64.deb"
    "pool/main/l/linux/linux-libc-dev_4.4.0-21.37_amd64.deb"
    "pool/main/g/gcc-5/libgcc-5-dev_5.3.1-14ubuntu2_amd64.deb"
    "pool/main/g/gccgo-6/libgcc1_6.0.1-0ubuntu1_amd64.deb"
)

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "Downloading and extracting Ubuntu 16.04 (Xenial) packages..."

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
