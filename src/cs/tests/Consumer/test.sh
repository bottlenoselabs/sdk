#!/usr/bin/env bash
# Packs Sdk into the local folder feed (/nupkg) and builds this consumer against it.
set -euo pipefail
cd "$(dirname "$0")"

rm -rf ../../../../nupkg .packages obj artifacts
dotnet pack ../../production/Sdk --nologo --configuration Release
dotnet build --nologo --configuration Release
