#!/usr/bin/env bash
# Builds the SDL native library from the ext/SDL submodule into lib/<runtime identifier>/, with the file name .NET loads:
#   Windows: SDL3.dll   macOS: libSDL3.dylib   Linux: libSDL3.so
#
# Usage: ext/build-sdl.sh [runtime identifier]
#   The runtime identifier defaults to this computer's, for example osx-arm64. Each operating system can only build for itself;
#   Windows and macOS can also build for their other CPU architecture (win-x64 and win-arm64, osx-x64 and osx-arm64).
#
# Needs: CMake, and a C compiler: Visual Studio (Windows), Xcode command line tools (macOS), or GCC (Linux) with SDL's
# development packages (see https://wiki.libsdl.org/SDL3/README-linux).
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$root/ext/SDL"

# The oldest macOS that .NET 11 supports; matches GameAppMinimumMacOSVersion
macos_minimum_version="15.0"

# HOST_RID, HOST_RID_OS: this computer's runtime identifier and its operating system part
# shellcheck source=src/bash/host-rid.sh
source "$root/src/bash/host-rid.sh"

rid="${1:-$HOST_RID}"
if [[ "${rid%%-*}" != "$HOST_RID_OS" ]]; then
    echo "Can't build $rid on this computer ($HOST_RID); build it on its own operating system" >&2
    exit 1
fi

if [[ ! -f "$source_dir/CMakeLists.txt" ]]; then
    echo "SDL source not found in ext/SDL; run: git submodule update --init --depth 1 ext/SDL" >&2
    exit 1
fi
command -v cmake > /dev/null || { echo "CMake is not installed" >&2; exit 1; }

case "$rid" in
    win-x64) platform_flags=(-A x64) ;;
    win-arm64) platform_flags=(-A ARM64) ;;
    osx-x64) platform_flags=(-D CMAKE_OSX_ARCHITECTURES=x86_64 -D CMAKE_OSX_DEPLOYMENT_TARGET="$macos_minimum_version") ;;
    osx-arm64) platform_flags=(-D CMAKE_OSX_ARCHITECTURES=arm64 -D CMAKE_OSX_DEPLOYMENT_TARGET="$macos_minimum_version") ;;
    linux-x64 | linux-arm64) platform_flags=() ;;
    *) echo "Unsupported runtime identifier: $rid" >&2; exit 1 ;;
esac

build_dir="$root/ext/.build/SDL-$rid"
install_dir="$build_dir/install"
output_dir="$root/lib/$rid"
rm -rf "$build_dir"
mkdir -p "$output_dir"

echo "Building SDL $(git -C "$source_dir" describe --tags --always 2> /dev/null || echo "(unknown version)") for $rid"
cmake -S "$source_dir" -B "$build_dir" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_INSTALL_PREFIX="$install_dir" \
    -D SDL_SHARED=ON \
    -D SDL_STATIC=OFF \
    -D SDL_TEST_LIBRARY=OFF \
    -D SDL_TESTS=OFF \
    -D SDL_EXAMPLES=OFF \
    "${platform_flags[@]}"
cmake --build "$build_dir" --config Release --parallel
cmake --install "$build_dir" --config Release

# Copy the library under the name .NET looks for with [LibraryImport("SDL3")]
case "$rid" in
    win-*)
        cp -f "$install_dir/bin/SDL3.dll" "$output_dir/SDL3.dll"
        ;;
    osx-*)
        # The real file is libSDL3.0.dylib; libSDL3.dylib is a symbolic link to it
        cp -f "$install_dir/lib/libSDL3.0.dylib" "$output_dir/libSDL3.dylib"
        install_name_tool -id "@rpath/libSDL3.dylib" "$output_dir/libSDL3.dylib"
        # Changing the install name breaks the signature; re-sign so the library can go inside a signed .app bundle
        codesign --force --sign - "$output_dir/libSDL3.dylib"
        ;;
    linux-*)
        # The real file is libSDL3.so.0.<version>; libSDL3.so and libSDL3.so.0 are symbolic links to it
        real_file="$(find "$install_dir/lib" -maxdepth 1 -type f -name "libSDL3.so.*" | head -n 1)"
        cp -f "$real_file" "$output_dir/libSDL3.so"
        ;;
esac

echo "Built: $(ls "$output_dir")"
