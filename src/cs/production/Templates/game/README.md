# MyGame

A C# game on [`bottlenoselabs.Sdk.GameApp`](https://github.com/bottlenoselabs/sdk).

## Develop

```bash
dotnet run --project ./src/cs/MyGame
```

Debug builds use the JIT for fast iteration. Put assets (images, sounds, shaders) in `src/cs/MyGame/Assets/`; they are copied next to the executable.

## Publish

```bash
dotnet publish ./src/cs/MyGame --runtime osx-arm64
```

Release builds are compiled to native code with NativeAOT, with no debug symbols in the published folder. Publishing makes the platform's app format: `MyGame.exe` on Windows, `MyGame.app` on macOS, and `MyGame.AppDir` on Linux, which CI turns into one `MyGame.AppImage` file. Put a square `icon.png` (1024×1024 or larger) next to `MyGame.csproj` to use your own icon.

On every push, CI publishes the game for Windows, macOS and Linux and uploads each build as an artifact.
