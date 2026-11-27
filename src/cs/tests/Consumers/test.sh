#!/usr/bin/env bash
# Packs the SDKs into the local folder feed (/nupkg) and builds one consumer project per SDK against them.
# Directory.Build.targets checks the SDK's properties after each build.
set -euo pipefail
cd "$(dirname "$0")"

# Reused MSBuild nodes cache SDK files in memory, so a re-packed SDK could be ignored
export MSBUILDDISABLENODEREUSE=1

rm -rf ../../../../nupkg .packages artifacts
dotnet pack --disable-build-servers ../.. --nologo --configuration Release

for project in Console WebApp GameApp; do
    # Debug, with code coverage turned off to check the opt-out
    dotnet build --disable-build-servers "$project" --nologo --configuration Debug -p:IsEnabledCodeCoverage=false

    # Release: publish with NativeAOT
    dotnet publish --disable-build-servers "$project" --nologo --configuration Release
done

# The published game has no debug symbols or documentation files
leftovers="$(find artifacts/publish/GameApp \( -name "*.pdb" -o -name "*.dbg" -o -name "*.dSYM" -o -name "*.xml" \) -print)"
if [[ -n "$leftovers" ]]; then
    echo "The published game should not contain:" >&2
    echo "$leftovers" >&2
    exit 1
fi

# Run the native executables; a non-zero exit code fails the script. The web app is not run, since it would not exit.
for project in Console GameApp; do
    # Only the top of the publish folder: symbol folders such as Game.dSYM hold a file with the same name
    executable=""
    for candidate in artifacts/publish/"$project"/release*/"$project" artifacts/publish/"$project"/release*/"$project".exe; do
        if [[ -f "$candidate" ]]; then
            executable="$candidate"
        fi
    done
    if [[ -z "$executable" ]]; then
        echo "No published executable found in artifacts/publish/$project" >&2
        exit 1
    fi
    "$executable"
done
