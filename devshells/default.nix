{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    # Build tools
    cmake
    ninja
    python3
    git
    pkg-config

    # Compilers (unwrapped to avoid Nix-specific behavior)
    llvmPackages.clang-unwrapped
    llvmPackages.compiler-rt
    llvmPackages.lld

    # Libraries
    zlib
    ncurses
    libxml2
    libffi

    # Optional but useful
    ccache
  ];

  shellHook = ''
    export CLANG_CONFIG_FILE_SYSTEM_DIR="$PWD/sysroot-jammy"
  '';
}
