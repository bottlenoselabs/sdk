# Getting started

This guide gets you from nothing to a running project on a Bottlenose Labs SDK. It assumes you know C# and the `dotnet` command line, but not MSBuild SDKs.

> [!NOTE]
> The packages are not on NuGet.org yet. Until the first release, replace `<version>` below with a version from [Releases](https://github.com/bottlenoselabs/sdk/releases), or build them yourself: see [CONTRIBUTING.md](../CONTRIBUTING.md#testing).

## What you need

- The [.NET 11 SDK](https://dotnet.microsoft.com/download).
- Git.
- To publish native executables (`dotnet publish` in Release), the C/C++ linker of your operating system:
  - Windows: Visual Studio or the Build Tools, with the "Desktop development with C++" workload.
  - macOS: Xcode (`xcode-select --install` is enough to build; the full Xcode is not required).
  - Linux: `clang` and `zlib` development files, for example `sudo apt install clang zlib1g-dev`.

You can build and run in Debug without the linker; it is only needed for NativeAOT.

## Start a new repository from a template

The quickest start. Each template creates a whole repository: the project, `global.json`, `.gitignore`, `.editorconfig`, a README, and GitHub Actions workflows.

```bash
dotnet new install bottlenoselabs.Templates::<version>
dotnet new bl-game --name MyGame
cd MyGame
git init
dotnet run --project ./src/cs/MyGame
```

| Template | Creates |
| --- | --- |
| `bl-game` | A game on `bottlenoselabs.Sdk.GameApp`. CI builds it, then publishes it for Windows, macOS and Linux |
| `bl-webapp` | A minimal-API web app on `bottlenoselabs.Sdk.WebApp`, ready for NativeAOT |
| `bl-lib` | A library on `bottlenoselabs.Sdk`, with a workflow that releases it to NuGet.org |

Run `git init` before the first build. The SDK puts all build output in an `artifacts/` folder at the Git repository root; outside a Git repository it falls back to a folder next to each project.

The new repository pins the SDK and the reusable workflows to the same release the templates came from. To upgrade later, change the versions in `global.json` and the `@v<version>` tags in `.github/workflows/`.

## Use an SDK in an existing project

1. Pin the SDK version in a `global.json` file at the root of your repository. List only the SDKs you use:

   ```json
   {
     "sdk": {
       "version": "11.0.100",
       "rollForward": "latestFeature"
     },
     "msbuild-sdks": {
       "bottlenoselabs.Sdk": "<version>",
       "bottlenoselabs.Sdk.WebApp": "<version>",
       "bottlenoselabs.Sdk.GameApp": "<version>"
     }
   }
   ```

2. Change the `Sdk` attribute in your `.csproj`:

   | If the project is | Replace | With |
   | --- | --- | --- |
   | A library, console app or tool | `Microsoft.NET.Sdk` | `bottlenoselabs.Sdk` |
   | An ASP.NET Core web app | `Microsoft.NET.Sdk.Web` | `bottlenoselabs.Sdk.WebApp` |
   | A game | `Microsoft.NET.Sdk` | `bottlenoselabs.Sdk.GameApp` |

   ```xml
   <Project Sdk="bottlenoselabs.Sdk">

     <PropertyGroup>
       <OutputType>Exe</OutputType>
       <TargetFramework>net11.0</TargetFramework>
     </PropertyGroup>

   </Project>
   ```

3. Remove settings the SDK now provides, such as `Nullable`, `ImplicitUsings`, `LangVersion` and `AllowUnsafeBlocks`. See the [reference](reference.md) for the full list.

4. Build. The SDK turns on all .NET analyzers and treats warnings as errors, so an existing project usually needs some cleanup on the first build. To turn a rule down while you work through it, add it to `.editorconfig`:

   ```ini
   [*.cs]
   dotnet_diagnostic.CA1515.severity = suggestion
   ```

## Debug and Release

The SDKs use the two build configurations for two different jobs:

| | Debug | Release |
| --- | --- | --- |
| For | Prototyping and day-to-day work | Shipping |
| Compiles to | .NET IL, run by the JIT | Native code, with NativeAOT (`dotnet publish` only) |
| Build speed | Fast | Slower |
| Startup | JIT warm-up | Instant, no JIT |

```bash
dotnet run --project ./src/cs/MyGame                         # Debug
dotnet publish ./src/cs/MyGame --runtime osx-arm64           # Release, native
```

`dotnet publish` uses Release by default. `dotnet build -c Release` and `dotnet run -c Release` still use the JIT; only `dotnet publish` compiles to native code.

NativeAOT can't run code that depends on runtime code generation or unbounded reflection. The SDK turns on the NativeAOT and trimming analyzers in Debug too, so you find those problems while you write the code rather than when you first publish.

## Next

- [Games](games.md): assets, icons, packaging for each platform.
- [Web apps](web-apps.md): writing ASP.NET Core code that works with NativeAOT.
- [Workflows](workflows.md): the reusable GitHub Actions workflows.
- [Reference](reference.md): every property the SDKs set.
