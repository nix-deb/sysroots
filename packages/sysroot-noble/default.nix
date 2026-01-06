{ stdenvNoCC, fetchurl, ... }:

let
  debs = [
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.39-0ubuntu8_amd64.deb";
      hash = "sha256-rzbHrHcHcP49PBDoXWvFOOduV1cLp9t9OX+59lR4PvM=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.39-0ubuntu8_amd64.deb";
      hash = "sha256-HwO3kiPZzxpu06ZI9pQmGdy5eyiE26j9EuJitnceJHo=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_6.8.0-31.31_amd64.deb";
      hash = "sha256-IcYxuk2j042SoTPiiooUJ44eABdO0TWiBmHR5TLgXKU=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-13/libgcc-13-dev_13.2.0-23ubuntu4_amd64.deb";
      hash = "sha256-02yay5ad03/cBJYSBxXYu6Z6XMQ6DCVpcXMU5q2AAgw=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-14/libgcc-s1_14-20240412-0ubuntu1_amd64.deb";
      hash = "sha256-o579yqIkXwJtwyVM4U/P8lX8QwoXBkYytrp8Xal0qRI=";
    }
  ];

  srcs = map (d: fetchurl { inherit (d) url hash; }) debs;
in
stdenvNoCC.mkDerivation {
  pname = "sysroot-noble";
  version = "2.39";

  dontUnpack = true;

  buildPhase = ''
    for deb in ${toString srcs}; do
      echo "Extracting $deb"
      ar x "$deb"
      tar xf data.tar.*
      rm -f data.tar.* control.tar.* debian-binary
    done
  '';

  installPhase = ''
    mkdir -p $out
    cp -r lib lib64 usr $out/ 2>/dev/null || true
    cp -r etc $out/ 2>/dev/null || true

    # Fix absolute symlinks
    find $out -type l | while read -r link; do
      target=$(readlink "$link")
      if [[ "$target" == /* ]]; then
        newrel=$(realpath -m --relative-to="$(dirname "$link")" "$out$target")
        ln -sf "$newrel" "$link"
      fi
    done

    # Noble uses unified /usr layout, fix linker scripts
    cat > $out/usr/lib/x86_64-linux-gnu/libc.so << 'LDSCRIPT'
    /* GNU ld script */
    OUTPUT_FORMAT(elf64-x86-64)
    GROUP ( libc.so.6 libc_nonshared.a  AS_NEEDED ( ../../lib64/ld-linux-x86-64.so.2 ) )
    LDSCRIPT

    cat > $out/usr/lib/x86_64-linux-gnu/libm.so << 'LDSCRIPT'
    /* GNU ld script */
    OUTPUT_FORMAT(elf64-x86-64)
    GROUP ( libm.so.6  AS_NEEDED ( libmvec.so.1 ) )
    LDSCRIPT
  '';

  meta = {
    description = "Ubuntu 24.04 (Noble) sysroot with glibc 2.39";
    platforms = [ "x86_64-linux" ];
  };
}
