#!/usr/bin/env bash
# Finds the .NET runtime identifier (RID) of this computer, for example osx-arm64, win-x64 or linux-x64.
# See https://learn.microsoft.com/dotnet/core/rid-catalog
#
# Source it to set variables:
#   source src/bash/host-rid.sh
#   echo "$HOST_RID"        # osx-arm64
#   echo "$HOST_RID_OS"     # osx
#   echo "$HOST_RID_ARCH"   # arm64
#
# Or run it to print the runtime identifier:
#   src/bash/host-rid.sh    # osx-arm64

# Prints the runtime identifier, or an error on stderr and returns 1 for an operating system or CPU .NET doesn't support
host_rid() {
    local os arch

    case "$(uname -s)" in
        Darwin) os="osx" ;;
        Linux) os="linux" ;;
        MINGW* | MSYS* | CYGWIN*) os="win" ;;
        *) echo "host-rid.sh: unsupported operating system '$(uname -s)'" >&2; return 1 ;;
    esac

    case "$(uname -m)" in
        x86_64 | amd64) arch="x64" ;;
        arm64 | aarch64) arch="arm64" ;;
        *) echo "host-rid.sh: unsupported CPU architecture '$(uname -m)'" >&2; return 1 ;;
    esac

    # A shell running under Rosetta on an Apple Silicon Mac reports x86_64; the computer is arm64
    if [[ "$os" == "osx" && "$arch" == "x64" && "$(sysctl -n sysctl.proc_translated 2> /dev/null)" == "1" ]]; then
        arch="arm64"
    fi

    echo "$os-$arch"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # Run directly: print it
    host_rid
else
    # Sourced: set the variables, without exiting the caller's shell on failure
    if HOST_RID="$(host_rid)"; then
        HOST_RID_OS="${HOST_RID%%-*}"
        HOST_RID_ARCH="${HOST_RID#*-}"
        export HOST_RID HOST_RID_OS HOST_RID_ARCH
    else
        unset HOST_RID HOST_RID_OS HOST_RID_ARCH
        return 1
    fi
fi
