{ stdenvNoCC, fetchurl, ... }:

let
  debs = [
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6_2.23-0ubuntu3_amd64.deb";
      hash = "sha256-aNaaD7La51eKKnBUvAzV8JlNUj9g1UC8Zwj/Py+zPhg=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/libc6-dev_2.23-0ubuntu3_amd64.deb";
      hash = "sha256-FuaGlUkfoHDgYRL6VkdzK7gxZMLDxXMndMFHL83XnOI=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/l/linux/linux-libc-dev_4.4.0-21.37_amd64.deb";
      hash = "sha256-t5u2GuAYpFIYUlMHMwHzqKiUWsoymimTgGjgVWAIk0c=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gcc-5/libgcc-5-dev_5.3.1-14ubuntu2_amd64.deb";
      hash = "sha256-nHQASEwpiuKORLPiJl6JDm13j8VGdjKqTDC74fUbw6A=";
    }
    {
      url = "http://archive.ubuntu.com/ubuntu/pool/main/g/gccgo-6/libgcc1_6.0.1-0ubuntu1_amd64.deb";
      hash = "sha256-bjdNe27h/7z/VocFt/nse5vvv88X5oOiHvZIDcnQz+A=";
    }
  ];

  srcs = map (d: fetchurl { inherit (d) url hash; }) debs;
in
stdenvNoCC.mkDerivation {
  pname = "sysroot-xenial";
  version = "2.23";

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
    description = "Ubuntu 16.04 (Xenial) sysroot with glibc 2.23";
    platforms = [ "x86_64-linux" ];
  };
}
