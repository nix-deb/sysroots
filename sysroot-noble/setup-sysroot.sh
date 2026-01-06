#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

PACKAGES=(
    "pool/main/g/glibc/libc6_2.39-0ubuntu8_amd64.deb"
    "pool/main/g/glibc/libc6-dev_2.39-0ubuntu8_amd64.deb"
    "pool/main/l/linux/linux-libc-dev_6.8.0-31.31_amd64.deb"
    "pool/main/g/gcc-13/libgcc-13-dev_13.2.0-23ubuntu4_amd64.deb"
    "pool/main/g/gcc-14/libgcc-s1_14-20240412-0ubuntu1_amd64.deb"
)

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "Downloading and extracting Ubuntu 24.04 (Noble) packages..."

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

echo "Fixing linker scripts..."
# Noble puts everything in /usr, so linker scripts need relative paths
cat > usr/lib/x86_64-linux-gnu/libc.so << 'LDSCRIPT'
/* GNU ld script */
OUTPUT_FORMAT(elf64-x86-64)
GROUP ( libc.so.6 libc_nonshared.a  AS_NEEDED ( ../../lib64/ld-linux-x86-64.so.2 ) )
LDSCRIPT

cat > usr/lib/x86_64-linux-gnu/libm.so << 'LDSCRIPT'
/* GNU ld script */
OUTPUT_FORMAT(elf64-x86-64)
GROUP ( libm.so.6  AS_NEEDED ( libmvec.so.1 ) )
LDSCRIPT

echo "Done. Sysroot ready in $(pwd)"
