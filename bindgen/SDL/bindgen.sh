#!/usr/bin/env bash
# Generates the C# bindings for SDL (src/cs/production/SDL.Interop/Generated) from the headers in the ext/SDL submodule, with the
# c2ffi and c2cs tools pinned in dotnet-tools.json.
#
# Usage: bindgen/SDL/bindgen.sh <step>
#   extract    Read SDL's C API for this operating system's targets (config-extract.json) into ffi/<target>.json.
#              Each operating system can only extract its own targets, so CI runs this on Windows, macOS and Linux.
#   merge      Combine every ffi/<target>.json into ffi-x/cross-platform.json.
#   generate   Write the C# bindings from ffi-x/cross-platform.json (config-generate-cs.json).
#
# c2ffi can exit with 0 even when extraction fails, so each step checks its output files instead of trusting the exit code.
set -euo pipefail

directory="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$directory/../.." && pwd)"
cd "$directory"

# HOST_RID_OS: this computer's operating system part of the .NET runtime identifier (win, osx, linux)
# shellcheck source=src/bash/host-rid.sh
source "$root/src/bash/host-rid.sh"

case "$HOST_RID_OS" in
    win) targets=(x86_64-pc-windows-msvc aarch64-pc-windows-msvc) ;;
    osx) targets=(x86_64-apple-darwin aarch64-apple-darwin) ;;
    linux) targets=(x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu) ;;
esac

require_file() {
    if [[ ! -s "$1" ]]; then
        echo "bindgen.sh: $2 did not produce $1" >&2
        exit 1
    fi
}

(cd "$root" && dotnet tool restore > /dev/null)

case "${1:-}" in
    extract)
        [[ -f "$root/ext/SDL/include/SDL3/SDL.h" ]] || { echo "SDL headers not found; run: git submodule update --init --depth 1 ext/SDL" >&2; exit 1; }
        rm -rf ./ffi
        dotnet tool run c2ffi extract --config ./config-extract.json
        for target in "${targets[@]}"; do
            require_file "./ffi/$target.json" "c2ffi extract"
        done
        ;;
    merge)
        rm -rf ./ffi-x
        dotnet tool run c2ffi merge --inputDirectoryPath ./ffi --outputFilePath ./ffi-x/cross-platform.json
        require_file ./ffi-x/cross-platform.json "c2ffi merge"
        ;;
    generate)
        require_file ./ffi-x/cross-platform.json "the merge step"
        dotnet tool run c2cs generate --config ./config-generate-cs.json
        require_file "$root/src/cs/production/SDL.Interop/Generated/SDL.g.cs" "c2cs generate"
        ;;
    *)
        echo "Usage: bindgen/SDL/bindgen.sh extract|merge|generate" >&2
        exit 1
        ;;
esac
