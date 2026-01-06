{ stdenvNoCC, fetchurl, ... }:

let
  debs = [
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.27-3ubuntu1_amd64.deb";
      hash = "sha256-Hh64b9ZGqmj3FE7Gkrg3trNS0hWIDGotDJLBnTaThCc=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.27-3ubuntu1_amd64.deb";
      hash = "sha256-5CbHCpQKfQxclYI6X9AfJr2LywjRCd8vjJbEOdqNxEA=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_4.15.0-20.21_amd64.deb";
      hash = "sha256-SnP8XqLQKE6cnITLpoy+WIBQWvuuCjIBxlwzba+Pgjk=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-7/libgcc-7-dev_7.3.0-16ubuntu3_amd64.deb";
      hash = "sha256-vsvroz04JKo8DRseYmU/zud263ytYx3wdI+ncDLik8Y=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-8/libgcc1_8-20180414-1ubuntu2_amd64.deb";
      hash = "sha256-xabfUn/f4NpF/wU4QUU1oEpnU+k6n1kCaJzxpzJlQjs=";
    }
  ];

  srcs = map (d: fetchurl { inherit (d) url hash; }) debs;
in
stdenvNoCC.mkDerivation {
  pname = "sysroot-bionic";
  version = "2.27";

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
  '';

  meta = {
    description = "Ubuntu 18.04 (Bionic) sysroot with glibc 2.27";
    platforms = [ "x86_64-linux" ];
  };
}
