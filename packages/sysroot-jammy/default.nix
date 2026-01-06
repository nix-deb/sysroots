{ stdenvNoCC, fetchurl, ... }:

let
  debs = [
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.35-0ubuntu3_amd64.deb";
      hash = "sha256-6pon4OvdDPycdQ2U+AdPOjXR+X3Md64Ew3D7SYprbbI=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.35-0ubuntu3_amd64.deb";
      hash = "sha256-zDfKtcYLz+S78omoAC82mUmkHtRui1GgUDoAEJk3DFY=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_5.15.0-25.25_amd64.deb";
      hash = "sha256-GyqTAgWTyelKJfdQzkQtpabo/0iiD1LOyS38P6NTNtg=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-11/libgcc-11-dev_11.2.0-19ubuntu1_amd64.deb";
      hash = "sha256-ra5aMBx4mcG86K4mtUI3FqR+UW3yXAnW1TZge8NIU7w=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-12/libgcc-s1_12-20220319-1ubuntu1_amd64.deb";
      hash = "sha256-yak3IUMb4HVXyBDX4bJMOzxR85gzTe0QQ2KmikFbnmE=";
    }
  ];

  srcs = map (d: fetchurl { inherit (d) url hash; }) debs;
in
stdenvNoCC.mkDerivation {
  pname = "sysroot-jammy";
  version = "2.35";

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
    description = "Ubuntu 22.04 (Jammy) sysroot with glibc 2.35";
    platforms = [ "x86_64-linux" ];
  };
}
