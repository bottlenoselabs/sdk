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

Release builds are compiled to native code with NativeAOT, with no debug symbols in the published folder. On every push, CI publishes the game for Windows, macOS and Linux and uploads each build as an artifact.
