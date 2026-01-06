{ stdenvNoCC, fetchurl, ... }:

let
  debs = [
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.31-0ubuntu9_amd64.deb";
      hash = "sha256-hHpo5fHsLNTm/BkcXq8FR0Rd1cRzx2F8BoukRB9jspI=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.31-0ubuntu9_amd64.deb";
      hash = "sha256-rbePOPsAx2r0OEvnpMX0HaJC4FvqawSD4Dt+DIZzhHc=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_5.4.0-26.30_amd64.deb";
      hash = "sha256-p9WUIBNKgwfrEe95to4rNcrceUpg+CyH9Fg+N8dj/QE=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-9/libgcc-9-dev_9.3.0-10ubuntu2_amd64.deb";
      hash = "sha256-0dtN5ZtBhOUCQHoqv94j7RqWblkPF7TSBr20+7ffAEA=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-10/libgcc-s1_10-20200411-0ubuntu1_amd64.deb";
      hash = "sha256-+2n0dJDSKYitihs8GdUpLhzNvTBmHu3NaA+aeLm1XWA=";
    }
  ];

  srcs = map (d: fetchurl { inherit (d) url hash; }) debs;
in
stdenvNoCC.mkDerivation {
  pname = "sysroot-focal";
  version = "2.31";

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
    description = "Ubuntu 20.04 (Focal) sysroot with glibc 2.31";
    platforms = [ "x86_64-linux" ];
  };
}
