# bottlenoselabs.Sdk

A C# SDK with common stuff for all C# projects at Bottlenose Labs. 

## Developers: How to use

There is one SDK per kind of project. Each one wraps a Microsoft SDK and adds the same Bottlenose Labs settings on top.

| SDK | Wraps | For |
| --- | --- | --- |
| `bottlenoselabs.Sdk` | `Microsoft.NET.Sdk` | Libraries, console apps, tools |
| `bottlenoselabs.Sdk.WebApp` | `Microsoft.NET.Sdk.Web` | ASP.NET Core web apps |
| `bottlenoselabs.Sdk.GameApp` | `Microsoft.NET.Sdk` | Games |

1. Pin the SDK versions in a `global.json` file above your C# projects. List only the ones you use:

   ```json
   {
     "msbuild-sdks": {
       "bottlenoselabs.Sdk": "2026.11.27",
       "bottlenoselabs.Sdk.WebApp": "2026.11.27",
       "bottlenoselabs.Sdk.GameApp": "2026.11.27"
     }
   }
   ```

2. Use the SDK in your `.csproj` instead of the Microsoft one:

   ```xml
   <Project Sdk="bottlenoselabs.Sdk">

     <PropertyGroup>
       <OutputType>Exe</OutputType>
       <TargetFramework>net11.0</TargetFramework>
     </PropertyGroup>

   </Project>
   ```

   A game needs nothing else:

   ```xml
   <Project Sdk="bottlenoselabs.Sdk.GameApp" />
   ```

## What every SDK sets

| Area | Property | Value |
| --- | --- | --- |
| Output | `GitRepositoryPath` | Closest directory above the project with a `.git` folder or file (worktrees and submodules included) |
| Output | `UseArtifactsOutput` | `true` |
| Output | `ArtifactsPath` | `<Git repository root>/artifacts`, or `<project directory>/artifacts` outside a Git repository |
| Project | `Company`, `Authors` | `bottlenoselabs` |
| Project | `Copyright` | `© <current year> Bottlenose Labs Inc.` |
| Project | `Version` | `0.0.0.0-pre` when not set |
| Language | `LangVersion` | `latest` |
| Language | `Nullable`, `ImplicitUsings` | `enable` |
| Language | `AllowUnsafeBlocks` | `true` |
| Build | `GenerateDocumentationFile` | `true` |
| Build | `MSBuildTreatWarningsAsErrors` | `true` |
| Compilation | `PublishAot` | `true` for executables in `Release`: `dotnet publish` compiles to native code with NativeAOT. `Debug` uses the JIT for fast builds |
| Compilation | `OptimizationPreference` | `Speed` for executables in `Release` |
| Compilation | `EnableAotAnalyzer`, `EnableTrimAnalyzer`, `EnableSingleFileAnalyzer` | `true` for executables in every configuration, so NativeAOT problems show up while prototyping |
| Compilation | `IsAotCompatible` | `true` for libraries targeting .NET 8 or later |
| Platform | `IsWindows`, `IsMacOS`, `IsLinux`, `IsFreeBSD` | `true` on the current operating system |
| Platform | `Architecture`, `Is32Bit`, `Is64Bit` | Current CPU architecture, in lowercase (`x64`, `arm64`, ...) |
| Platform | `DefineConstants` | `WINDOWS`, `MACOS`, `LINUX` or `FREEBSD` |
| Code analysis | `IsEnabledAnalyzers` | `true`; set to `false` to turn off |
| Code analysis | `AnalysisMode`, `AnalysisLevel` | `all`, `latest` |
| Code analysis | `TreatWarningsAsErrors` | `true` |
| Code coverage | `IsEnabledCodeCoverage` | Not set; set to `false` to exclude the assembly from coverage with `[ExcludeFromCodeCoverage]` |
| Code analysis | Rules | `CodeAnalysis/BottlenoseLabs.globalconfig` |
| NuGet | `IsPackable` | `false` |
| NuGet | `PackageOutputPath` | `<Git repository root>/nupkg`, or `<project directory>/nupkg` outside a Git repository |
| NuGet | `PackageId` | `bottlenoselabs.<AssemblyName>` when not set |
| NuGet | `PackageIcon` | Bottlenose Labs `icon.png` when not set |

Everything above is set before your project file is read (the Compilation rows: right after it, using its `OutputType`), so any of it can be overridden in the `.csproj` or in a `Directory.Build.props` file.

## What `bottlenoselabs.Sdk.WebApp` adds

| Property | Value |
| --- | --- |
| `EnableRequestDelegateGenerator`, `EnableConfigurationBindingGenerator` | `true` in every configuration, so minimal APIs work with NativeAOT and pass the analyzers in `Debug` too |

Because `Release` publishes with NativeAOT, use minimal APIs with `WebApplication.CreateSlimBuilder` and source-generated JSON. MVC, Razor Pages and most of Entity Framework Core are not NativeAOT-compatible and fail the analyzers.

## What `bottlenoselabs.Sdk.GameApp` adds

| Property | Value |
| --- | --- |
| `OutputType` | `Exe`; `WinExe` in `Release`, so Windows opens no console window behind the game |
| `TargetFramework` | `net<.NET version of the SDK in global.json>` when the project sets none |
| `InvariantGlobalization` | `true`: the same number and text formatting on every player's machine, and no ICU dependency on Linux |
| `GameAssetsDirectory` | `Assets`: everything in it is copied next to the executable on build and on publish, keeping the folder structure |
| `PublishDocumentationFile`, `PublishReferencesDocumentationFiles` | `false`: no `.xml` files in the published game |
| `IsEnabledPublishDebugSymbols` | Not set: debug symbols (`.pdb`, `.dSYM`, `.dbg`) stay in the build output for crash analysis but are kept out of the published game, so it is harder to reverse engineer. Set to `true` to publish them |
| `IsEnabledRuntimeMarshalling` | Not set: `[DisableRuntimeMarshalling]`, so P/Invoke calls into native libraries such as SDL pass blittable types straight through. Set to `true` to turn runtime marshalling back on |

To override an analyzer or code style rule, add it to an `.editorconfig` file in your repository:

```ini
[*.cs]
dotnet_diagnostic.IDE0055.severity = warning
```

## Reusable GitHub Actions workflows

Other repositories can call these workflows instead of copying them. Pin to a release tag of this repository, for example `@v2026.11.27`, so the workflows and the SDK version move together.

| Workflow | What it does |
| --- | --- |
| [`cs-build.yml`](.github/workflows/cs-build.yml) | Builds and tests on Windows, Linux and macOS (`runs-on`), then runs an optional `script` |
| [`cs-release.yml`](.github/workflows/cs-release.yml) | From the default branch only: packs, pushes to NuGet.org with trusted publishing, and creates a tagged GitHub release |

```yaml
jobs:
  build:
    uses: bottlenoselabs/sdk/.github/workflows/cs-build.yml@v2026.11.27
    with:
      path: ./src/cs
```

The inputs are documented at the top of each workflow file. `cs-release.yml` needs the calling job to grant `contents: write` and `id-token: write`, and a `NUGET_USER` secret.
