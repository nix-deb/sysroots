{
  description = "LLVM development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default = pkgs.mkShell {
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
        };
      });
    };
}
