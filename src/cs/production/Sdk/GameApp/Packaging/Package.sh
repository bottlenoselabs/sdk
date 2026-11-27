#!/usr/bin/env bash
# Turns a published game folder into the platform's app format, in place. Run by bottlenoselabs.Sdk.GameApp after `dotnet publish`.
#   macOS: <name>.app bundle with Info.plist, an .icns icon, and an ad-hoc code signature
#   Linux: <name>.AppDir (launcher, .desktop file, icon) that appimagetool turns into one AppImage file
# Usage: Package.sh <osx|linux> <publish folder> <executable name> <display name> <bundle identifier> <version> <minimum macOS version> <icon PNG>
set -euo pipefail

os="$1"
publish_dir="$2"
executable="$3"
display_name="$4"
bundle_identifier="$5"
version="$6"
minimum_macos_version="$7"
icon="$8"

cd "$publish_dir"

# Move everything that was published into the folder the app format runs the executable from
move_published_files() {
    local destination="$1"
    local top="$2"
    mkdir -p "$destination"
    find . -mindepth 1 -maxdepth 1 ! -name "$top" -exec mv {} "$destination/" \;
}

xml_escape() {
    local text="$1"
    text="${text//&/&amp;}"
    text="${text//</&lt;}"
    text="${text//>/&gt;}"
    printf '%s' "$text"
}

case "$os" in
    osx)
        app="$executable.app"
        rm -rf "$app"
        move_published_files "$app/Contents/MacOS" "$app"
        mkdir -p "$app/Contents/Resources"

        # Only code (the executable, native libraries) may be in Contents/MacOS, or code signing fails. Move everything else, such as
        # the Assets folder, to Contents/Resources, and link it back so the game still finds it next to the executable.
        for entry in "$app/Contents/MacOS"/* "$app/Contents/MacOS"/.[!.]*; do
            [[ -e "$entry" ]] || continue
            if [[ -f "$entry" ]] && file -b "$entry" | grep -q "^Mach-O"; then
                continue
            fi
            entry_name="$(basename "$entry")"
            mv "$entry" "$app/Contents/Resources/$entry_name"
            ln -s "../Resources/$entry_name" "$app/Contents/MacOS/$entry_name"
        done

        # Icon: every size macOS asks for, made from the one PNG with the tools macOS ships
        iconset="$(mktemp -d)/$executable.iconset"
        mkdir -p "$iconset"
        for size in 16 32 128 256 512; do
            sips -z "$size" "$size" "$icon" --out "$iconset/icon_${size}x${size}.png" > /dev/null
            sips -z "$((size * 2))" "$((size * 2))" "$icon" --out "$iconset/icon_${size}x${size}@2x.png" > /dev/null
        done
        iconutil --convert icns --output "$app/Contents/Resources/$executable.icns" "$iconset"
        rm -rf "$(dirname "$iconset")"

        cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleDisplayName</key>
  <string>$(xml_escape "$display_name")</string>
  <key>CFBundleExecutable</key>
  <string>$(xml_escape "$executable")</string>
  <key>CFBundleIconFile</key>
  <string>$(xml_escape "$executable").icns</string>
  <key>CFBundleIdentifier</key>
  <string>$(xml_escape "$bundle_identifier")</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$(xml_escape "$display_name")</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$(xml_escape "$version")</string>
  <key>CFBundleVersion</key>
  <string>$(xml_escape "$version")</string>
  <key>LSApplicationCategoryType</key>
  <string>public.app-category.games</string>
  <key>LSMinimumSystemVersion</key>
  <string>$(xml_escape "$minimum_macos_version")</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
EOF

        # Apple Silicon only runs signed code; an ad-hoc signature also covers the bundle's files. Distribution outside your own Macs
        # still needs a Developer ID signature and notarization.
        codesign --force --sign - "$app"
        ;;

    linux)
        appdir="$executable.AppDir"
        rm -rf "$appdir"
        move_published_files "$appdir/usr/bin" "$appdir"

        cat > "$appdir/AppRun" <<EOF
#!/bin/sh
# Starts the game from wherever the AppImage (or this folder) is
here="\$(dirname "\$(readlink -f "\$0")")"
exec "\$here/usr/bin/$executable" "\$@"
EOF
        chmod +x "$appdir/AppRun"

        cat > "$appdir/$executable.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$display_name
Exec=$executable
Icon=$executable
Categories=Game;
Terminal=false
EOF
        cp "$icon" "$appdir/$executable.png"
        ln -sf "$executable.png" "$appdir/.DirIcon"
        ;;

    *)
        echo "Package.sh: unknown operating system '$os'" >&2
        exit 1
        ;;
esac
