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

            # Compiler
            gcc

            # Libraries
            zlib
            ncurses
            libxml2
            libffi

            # Optional but useful
            ccache
            lld
          ];

          shellHook = ''
            echo "LLVM development environment"
            echo "Example build:"
            echo "  cmake -S llvm -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_PROJECTS='clang' -DLLVM_ENABLE_RUNTIMES='libcxx;libcxxabi'"
            echo "  ninja -C build"
          '';
        };
      });
    };
}
