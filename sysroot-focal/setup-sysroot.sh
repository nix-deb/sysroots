#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PACKAGES=(
    "pool/main/g/glibc/libc6_2.31-0ubuntu9_amd64.deb"
    "pool/main/g/glibc/libc6-dev_2.31-0ubuntu9_amd64.deb"
    "pool/main/l/linux/linux-libc-dev_5.4.0-26.30_amd64.deb"
    "pool/main/g/gcc-9/libgcc-9-dev_9.3.0-10ubuntu2_amd64.deb"
    "pool/main/g/gcc-10/libgcc-s1_10-20200411-0ubuntu1_amd64.deb"
)

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "Downloading and extracting Ubuntu 20.04 (Focal) packages..."

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
