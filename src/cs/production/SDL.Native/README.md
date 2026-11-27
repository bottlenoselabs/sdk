# bottlenoselabs.SDL.Native

The native [SDL 3](https://github.com/libsdl-org/SDL) library, built from SDL's source for:

| Platform | File |
| --- | --- |
| Windows x64, Arm64 | `runtimes/win-x64/native/SDL3.dll`, `runtimes/win-arm64/native/SDL3.dll` |
| macOS x64, Arm64 (macOS 15 or later) | `runtimes/osx-x64/native/libSDL3.dylib`, `runtimes/osx-arm64/native/libSDL3.dylib` |
| Linux x64, Arm64 (glibc 2.35 or later) | `runtimes/linux-x64/native/libSDL3.so`, `runtimes/linux-arm64/native/libSDL3.so` |

.NET picks the right file for the platform your app runs on, or is published for. Load it with `[LibraryImport("SDL3")]`.

SDL is licensed under the [zlib license](https://github.com/libsdl-org/SDL/blob/main/LICENSE.txt), included as `SDL-LICENSE.txt`.

Built by [bottlenoselabs/sdk](https://github.com/bottlenoselabs/sdk). For C# bindings, see `bottlenoselabs.SDL`.
