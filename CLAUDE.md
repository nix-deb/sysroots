# Sysroots for Building libc++ Against Older glibc

This repo provides sysroots for cross-compiling libc++ to target older glibc versions.

## Quick Start

```bash
# Set up a sysroot (e.g., jammy for glibc 2.35)
cd sysroot-jammy && ./setup-sysroot.sh

# Enter dev shell
nix develop

# Build libc++
cmake -S runtimes -B build -G Ninja \
  -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ \
  -DCMAKE_C_FLAGS="--config $PWD/sysroot-jammy/x86_64-linux-gnu.cfg" \
  -DCMAKE_CXX_FLAGS="--config $PWD/sysroot-jammy/x86_64-linux-gnu.cfg" \
  -DCMAKE_EXE_LINKER_FLAGS="--config $PWD/sysroot-jammy/x86_64-linux-gnu.cfg" \
  -DCMAKE_SHARED_LINKER_FLAGS="--config $PWD/sysroot-jammy/x86_64-linux-gnu.cfg" \
  -DLIBCXX_INCLUDE_TESTS=OFF -DLIBCXXABI_INCLUDE_TESTS=OFF -DLIBUNWIND_INCLUDE_TESTS=OFF
ninja -C build

# Verify glibc version requirements
objdump -T build/lib/libc++.so.1.0 | grep GLIBC | awk '{print $5}' | sort -Vu
```

## Available Sysroots

| Sysroot | glibc | GCC | Max GLIBC Required | Compatible With |
|---------|-------|-----|-------------------|-----------------|
| xenial  | 2.23  | 5   | GLIBC_2.17 | CentOS 7, RHEL 7, Ubuntu 14.04+ |
| bionic  | 2.27  | 7   | GLIBC_2.27 | Ubuntu 18.04+, Debian 10+, RHEL 8+ |
| focal   | 2.31  | 9   | GLIBC_2.27 | Ubuntu 18.04+, Debian 10+, RHEL 8+ |
| jammy   | 2.35  | 11  | GLIBC_2.34 | Ubuntu 22.04+, Debian 12+, RHEL 9+ |
| noble   | 2.39  | 13  | GLIBC_2.38 | Ubuntu 24.04+ |

## Key Learnings

### Clang Configuration Files

Use `--config <path>.cfg` to configure clang for sysroot builds. Key options:

```
--sysroot=<CFGDIR>           # Use <CFGDIR> as sysroot (expands to config file dir)
--target=x86_64-linux-gnu    # Target triple
-rtlib=libgcc                # Use libgcc runtime (not compiler-rt)
--gcc-toolchain=<CFGDIR>/usr # Find GCC CRT files here
-fuse-ld=lld                 # Use lld linker
-B<CFGDIR>/usr/lib/gcc/...   # Search path for CRT files (crtbeginS.o, etc.)
-L<path>                     # Library search paths
-nostdlib++                  # Don't link host C++ stdlib
```

### Why Clang Config Files?

CMAKE_SYSROOT alone doesn't work well because:
1. Nix's wrapped clang injects host paths that override sysroot
2. Using unwrapped clang requires explicit CRT file paths
3. Config files provide a clean way to bundle all flags

### Required Packages from Ubuntu

Each sysroot needs:
- `libc6` - glibc runtime (.so files)
- `libc6-dev` - glibc headers and static libs
- `linux-libc-dev` - Linux kernel headers
- `libgcc-N-dev` - GCC CRT files (crtbeginS.o, crtendS.o, libgcc.a)
- `libgcc-s1` or `libgcc1` - libgcc_s.so runtime

### Symlink Fixups

Ubuntu debs contain absolute symlinks. Fix them with:
```bash
find . -type l | while read -r link; do
  target=$(readlink "$link")
  if [[ "$target" == /* ]]; then
    newrel=$(realpath -m --relative-to="$(dirname "$link")" ".$target")
    ln -sf "$newrel" "$link"
  fi
done
```

### Noble (24.04) Special Case

Noble uses unified `/usr` layout. The linker scripts in `libc.so` and `libm.so` reference absolute paths that must be fixed to relative paths:

```
# libc.so needs:
GROUP ( libc.so.6 libc_nonshared.a AS_NEEDED ( ../../lib64/ld-linux-x86-64.so.2 ) )

# libm.so needs:
GROUP ( libm.so.6 AS_NEEDED ( libmvec.so.1 ) )
```

### Nix Flake Structure

Uses numtide/blueprint for flake organization:
- `devshells/default.nix` - Dev shell with clang, lld, cmake, ninja
- `packages/sysroot-*/default.nix` - Fixed-output derivations for sysroots
- `sysroot-*/setup-sysroot.sh` - Shell scripts for manual setup
- `sysroot-*/x86_64-linux-gnu.cfg` - Clang config files

### Debugging Tips

1. Check what glibc symbols are required:
   ```bash
   objdump -T lib.so | grep GLIBC | awk '{print $5}' | sort -Vu
   ```

2. See what clang is actually doing:
   ```bash
   clang --config path/to/config.cfg -v -c -xc /dev/null -o /dev/null
   ```

3. If linker can't find libraries, check:
   - Symlinks are relative, not absolute
   - Linker scripts (libc.so, libm.so) use relative paths
   - `-L` paths include sysroot lib directories
   - `-B` path points to GCC's CRT directory

### Common Errors

**"cannot find crtbeginS.o"**: Add `-B<sysroot>/usr/lib/gcc/x86_64-linux-gnu/<version>`

**"undefined symbol: __isoc23_*"**: Host glibc headers being used. The `--sysroot` isn't being respected, likely due to Nix wrapper. Use unwrapped clang.

**"cannot find libc.so.6 inside sysroot"**: Linker script has absolute paths. Fix with relative paths.
