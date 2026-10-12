# bottlenoselabs.Sdk

A C# SDK with common stuff for all C# projects at Bottlenose Labs. 

## Developers: How to use

1. Pin the SDK version in a `global.json` file above your C# projects:

   ```json
   {
     "msbuild-sdks": {
       "bottlenoselabs.Sdk": "1.0.0"
     }
   }
   ```

2. Use the SDK in your `.csproj` instead of `Microsoft.NET.Sdk`:

   ```xml
   <Project Sdk="bottlenoselabs.Sdk">

     <PropertyGroup>
       <OutputType>Exe</OutputType>
       <TargetFramework>net10.0</TargetFramework>
     </PropertyGroup>

   </Project>
   ```

## What the SDK sets

| Area | Property | Value |
| --- | --- | --- |
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
| Build | `TieredCompilation`, `PublishReadyToRun` | `false` |
| Platform | `IsWindows`, `IsMacOS`, `IsLinux`, `IsFreeBSD` | `true` on the current operating system |
| Platform | `Architecture`, `Is32Bit`, `Is64Bit` | Current CPU architecture, in lowercase (`x64`, `arm64`, ...) |
| Platform | `DefineConstants` | `WINDOWS`, `MACOS`, `LINUX` or `FREEBSD` |
| Code analysis | `IsEnabledAnalyzers` | `true`; set to `false` to turn off |
| Code analysis | `AnalysisMode`, `AnalysisLevel` | `all`, `latest` |
| Code analysis | `TreatWarningsAsErrors` | `true` |
| Code analysis | Rules | `CodeAnalysis/BottlenoseLabs.globalconfig` |
| NuGet | `IsPackable` | `false` |
| NuGet | `PackageOutputPath` | `<Git repository root>/nupkg` |
| NuGet | `PackageId` | `bottlenoselabs.<AssemblyName>` when not set |
| NuGet | `PackageIcon` | Bottlenose Labs `icon.png` when not set |

Everything above is set before your project file is read, so any of it can be overridden in the `.csproj` or in a `Directory.Build.props` file.

To override an analyzer or code style rule, add it to an `.editorconfig` file in your repository:

```ini
[*.cs]
dotnet_diagnostic.IDE0055.severity = warning
```

## Contributors

The SDK lives in `src/cs/production/Sdk`.

- `Sdk/Sdk.props` and `Sdk/Sdk.targets` are the SDK entry points that MSBuild loads.
- `Sdk.props` and `Sdk.targets` hold the settings, and `CodeAnalysis/` and `NuGet/` hold their own `.props` and `.targets`.
- The repository's own projects use `Microsoft.NET.Sdk` and import `Sdk.props` and `Sdk.targets` directly through `src/cs/Directory.Build.props` and `src/cs/Directory.Build.targets`.

To check the package end to end, run `src/cs/tests/Consumer/test.sh`. It packs the SDK into a local `nupkg` folder and builds a consumer project against it.
