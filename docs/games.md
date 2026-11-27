# Games

`bottlenoselabs.Sdk.GameApp` is the SDK for games. It does everything [`bottlenoselabs.Sdk`](reference.md) does, plus what a game needs to run well and ship on Windows, macOS and Linux.

A game project can be a single line:

```xml
<Project Sdk="bottlenoselabs.Sdk.GameApp" />
```

The SDK picks the output type, the target framework (the .NET version of the SDK in `global.json`), the assets folder, the icon and the platform packaging. Every setting below can be changed in the project file.

## Assets

Put images, sounds, shaders and other files in an `Assets` folder next to the project file. Everything in it is copied next to the executable when you build and when you publish, keeping the folder structure.

```text
src/cs/MyGame/
├── MyGame.csproj
├── Program.cs
└── Assets/
    └── Textures/
        └── player.png
```

Load assets relative to the executable:

```csharp
var path = Path.Combine(AppContext.BaseDirectory, "Assets", "Textures", "player.png");
```

This works in Debug, in Release, and inside the macOS `.app` bundle and the Linux AppImage.

To use another folder, set `GameAssetsDirectory`:

```xml
<PropertyGroup>
  <GameAssetsDirectory>Content</GameAssetsDirectory>
</PropertyGroup>
```

## Icon

Put a square `icon.png` next to the project file. One PNG is used for every platform: the Windows `.exe`, the macOS `.app` and the Linux AppImage. 1024×1024 or larger looks best; the SDK makes the smaller sizes.

Without one, the game gets a neutral game controller icon.

To use a file somewhere else, set `GameAppIcon` to its path. To use a hand-made Windows `.ico` file, set `ApplicationIcon`.

## Running and debugging

In Debug, the game runs on the JIT with a console window, so `Console.WriteLine` output and logs are visible. Builds are fast, and your IDE's debugger and hot reload work as usual.

```bash
dotnet run --project ./src/cs/MyGame
```

## Publishing

```bash
dotnet publish ./src/cs/MyGame --runtime win-x64      # on Windows
dotnet publish ./src/cs/MyGame --runtime osx-arm64    # on macOS
dotnet publish ./src/cs/MyGame --runtime linux-x64    # on Linux
```

Publishing compiles the game to native code with NativeAOT, optimized for speed. NativeAOT can only build for the operating system it runs on, so a Windows build needs a Windows machine, and so on. Use the [`cs-game-publish.yml`](workflows.md#cs-game-publishyml) workflow to build all of them in CI.

The output in `artifacts/publish/MyGame/release_<runtime>/` is in the platform's own app format:

| Platform | You get |
| --- | --- |
| Windows | `MyGame.exe` with your icon, and no console window |
| macOS | `MyGame.app`, a signed app bundle with your icon |
| Linux | `MyGame.AppDir`; the publish workflow turns it into a single `MyGame.AppImage` file |

To get a plain folder instead, set `IsEnabledPlatformPackaging` to `false`.

### Windows

The `.exe` has your icon and a manifest built in. The manifest:

- makes the game DPI aware on every monitor, so Windows doesn't stretch it and make it blurry on high-resolution displays;
- allows file paths longer than 260 characters;
- sets the code page to UTF-8 for native libraries that use the older Windows text APIs;
- never asks for administrator rights.

In Release the executable is a Windows GUI app, so no console window opens behind the game. To use your own manifest, set `ApplicationManifest`.

### macOS

`MyGame.app` contains:

- `Contents/MacOS/MyGame`: the executable.
- `Contents/Resources/`: the icon (`MyGame.icns`) and your assets. The assets are linked back into `Contents/MacOS/`, so the game finds them next to the executable.
- `Contents/Info.plist`: the name, version and bundle identifier.

You can change these values:

| Property | Default |
| --- | --- |
| `GameAppDisplayName` | The project's `Product`, which is the assembly name unless you set it |
| `GameAppBundleIdentifier` | `com.<company>.<assembly name>`, in lowercase |
| `GameAppMinimumMacOSVersion` | `15.0`, the oldest macOS that .NET 11 supports |
| `Version` | The version shown in Finder, without any pre-release suffix |

The bundle has an ad-hoc code signature, which lets it run on your own Macs, Apple Silicon included. To give the game to other people, macOS also needs a Developer ID signature and Apple notarization, or Gatekeeper refuses to open it. That needs a paid Apple Developer account, and the SDK doesn't do it for you yet.

### Linux

`dotnet publish` makes `MyGame.AppDir`. It contains the game in `usr/bin/`, a launcher (`AppRun`), a `.desktop` file and the icon. You can run it directly with `./MyGame.AppDir/AppRun`.

The [`cs-game-publish.yml`](workflows.md#cs-game-publishyml) workflow turns the AppDir into `MyGame.AppImage`: one executable file that runs on most Linux distributions. To make one yourself, download [appimagetool](https://github.com/AppImage/appimagetool) and run `appimagetool MyGame.AppDir`.

## Making the game hard to reverse engineer

Release builds help keep your code to yourself:

- NativeAOT compiles to machine code. There is no .NET IL in the published game for a decompiler to turn back into C#.
- Debug symbols (`.pdb` on Windows, `.dSYM` on macOS, `.dbg` on Linux) are left out of the published game, and the executable is stripped. They stay in `artifacts/bin/` so you can still read your own crash reports.

To publish the symbols anyway, set `IsEnabledPublishDebugSymbols` to `true`.

## Calling native libraries

Games often call C libraries such as SDL. The SDK turns off runtime marshalling for the game's assembly (`[DisableRuntimeMarshalling]`), so every P/Invoke passes blittable types straight through, with no hidden conversions or allocations. Use pointers, `unsafe` code (which the SDK allows) and C# function pointers for callbacks.

To turn runtime marshalling back on, set `IsEnabledRuntimeMarshalling` to `true`.

For SDL in C#, see [SDL3-cs](https://github.com/bottlenoselabs/SDL3-cs). Two planned improvements are tracked here: [adding SDL with one property](https://github.com/bottlenoselabs/sdk/issues/4), and [compiling shaders as part of the build](https://github.com/bottlenoselabs/sdk/issues/5).

## Other defaults

- **Invariant globalization.** Numbers and text are formatted the same way on every player's computer, whatever their language settings, so `1.5` is never written as `1,5` in a save file. It also removes the need for the ICU library on Linux. Set `InvariantGlobalization` to `false` if you need culture-specific formatting.
- **No `.xml` documentation files** in the published game.
