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

# Finds the executable a publish folder starts the game with: the .app bundle on macOS, the AppDir launcher on Linux,
# or the executable itself (Windows, and the console project). Only looks at the top level, since symbol folders such as
# Game.dSYM hold a file with the same name.
published_executable() {
    local folder="$1"
    local name="$2"
    local candidate
    for candidate in "$folder/$name.app/Contents/MacOS/$name" "$folder/$name.AppDir/AppRun" "$folder/$name" "$folder/$name.exe"; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    echo "No published executable found in $folder" >&2
    return 1
}

# Checks the platform app format that bottlenoselabs.Sdk.GameApp made from a publish folder. Pass `assets` as the third
# argument when the game has an Assets folder.
check_game_package() {
    local folder="$1"
    local name="$2"
    local assets="${3:-}"
    case "$(uname -s)" in
        Darwin)
            local app="$folder/$name.app"
            local files=("$app/Contents/Info.plist" "$app/Contents/Resources/$name.icns")
            [[ -n "$assets" ]] && files+=("$app/Contents/MacOS/Assets" "$app/Contents/Resources/Assets")
            for file in "${files[@]}"; do
                [[ -e "$file" ]] || { echo "Missing in the .app bundle: $file" >&2; return 1; }
            done
            plutil -lint "$app/Contents/Info.plist"
            codesign --verify --strict "$app"
            ;;
        Linux)
            local appdir="$folder/$name.AppDir"
            local files=("$appdir/AppRun" "$appdir/$name.desktop" "$appdir/$name.png" "$appdir/usr/bin/$name")
            [[ -n "$assets" ]] && files+=("$appdir/usr/bin/Assets")
            for file in "${files[@]}"; do
                [[ -e "$file" ]] || { echo "Missing in the AppDir: $file" >&2; return 1; }
            done
            [[ -x "$appdir/AppRun" ]] || { echo "AppRun is not executable" >&2; return 1; }
            ;;
    esac
}

# Run the native executables; a non-zero exit code fails the script. The web app is not run, since it would not exit.
check_game_package artifacts/publish/GameApp/release* GameApp assets
"$(published_executable artifacts/publish/Console/release* Console)"
"$(published_executable artifacts/publish/GameApp/release* GameApp)"

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

    # The new repository must not claim to be Bottlenose Labs' work. It may only name the SDK packages, this repository and SDL3-cs
    leaks="$(grep -rniE "bottlenose" "$repo" --exclude=nuget.config \
        | grep -viE "bottlenoselabs\.Sdk|bottlenoselabs/sdk|bottlenoselabs/SDL3-cs" || true)"
    if [[ -n "$leaks" ]]; then
        echo "The $template template generates Bottlenose Labs identity:" >&2
        echo "$leaks" >&2
        exit 1
    fi

    (cd "$repo" && dotnet build --disable-build-servers ./src/cs --nologo --configuration Debug)
    (cd "$repo" && dotnet build --disable-build-servers ./src/cs --nologo --configuration Release)
done

# The game template publishes and runs
(cd "$work/TestGame" && dotnet publish --disable-build-servers ./src/cs/TestGame --nologo --output "$work/TestGame-publish")
check_game_package "$work/TestGame-publish" TestGame
"$(published_executable "$work/TestGame-publish" TestGame)"
