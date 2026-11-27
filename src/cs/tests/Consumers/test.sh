#!/usr/bin/env bash
# Packs the SDKs and templates into the local folder feed (/nupkg), builds one consumer project per SDK against them,
# then creates a repository from each template and builds it. Directory.Build.targets checks the SDK's properties after each consumer build.
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

# Templates: create a repository from each one, outside this repository like a real new repository, and build it against the packed SDKs
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
# The generated nuget.config needs a native path on Windows (Git Bash `pwd -W`)
feed="$(cd ../../../../nupkg && (pwd -W 2>/dev/null || pwd))"
packages="$(cd "$work" && (pwd -W 2>/dev/null || pwd))/packages"
dotnet new install ../../../../nupkg/bottlenoselabs.Templates.*.nupkg --debug:custom-hive "$work/hive"

for pair in bl-game:TestGame bl-webapp:TestWebApp bl-lib:TestLibrary; do
    template="${pair%%:*}"
    name="${pair##*:}"
    repo="$work/$name"
    dotnet new "$template" --name "$name" --output "$repo" --debug:custom-hive "$work/hive"

    # Not part of the template: restore the SDKs from the local feed instead of nuget.org
    cat > "$repo/nuget.config" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <packageSources>
    <clear />
    <add key="local" value="$feed" />
    <add key="nuget.org" value="https://api.nuget.org/v3/index.json" />
  </packageSources>
  <packageSourceMapping>
    <packageSource key="local">
      <package pattern="bottlenoselabs.Sdk*" />
    </packageSource>
    <packageSource key="nuget.org">
      <package pattern="*" />
    </packageSource>
  </packageSourceMapping>
  <config>
    <add key="globalPackagesFolder" value="$packages" />
  </config>
</configuration>
EOF

    (cd "$repo" && dotnet build --disable-build-servers ./src/cs --nologo --configuration Debug)
    (cd "$repo" && dotnet build --disable-build-servers ./src/cs --nologo --configuration Release)
done

# The game template publishes and runs
(cd "$work/TestGame" && dotnet publish --disable-build-servers ./src/cs/TestGame --nologo --output "$work/TestGame-publish")
"$work/TestGame-publish/TestGame" 2>/dev/null || "$work/TestGame-publish/TestGame.exe"
