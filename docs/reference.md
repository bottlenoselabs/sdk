# Reference

Every property the SDKs set, and how to change it.

## How to change a setting

Every value below is a default. Set the property in your `.csproj`, or in a `Directory.Build.props` file to change it for every project under a folder:

```xml
<PropertyGroup>
  <IsEnabledAnalyzers>false</IsEnabledAnalyzers>
</PropertyGroup>
```

Most settings are applied before your project file is read, so your value wins. The few that depend on your project's `OutputType` or `Configuration` are applied right after your project file is read, and only when you haven't set them yourself.

To change how strict a single analyzer or code style rule is, use `.editorconfig`:

```ini
[*.cs]
dotnet_diagnostic.IDE0055.severity = warning
```

## Every SDK

These apply to `bottlenoselabs.Sdk`, `bottlenoselabs.Sdk.WebApp` and `bottlenoselabs.Sdk.GameApp`.

### Output

| Property | Default |
| --- | --- |
| `GitRepositoryPath` | The closest folder above the project with a `.git` folder or file. Worktrees and submodules count |
| `UseArtifactsOutput` | `true` |
| `ArtifactsPath` | `<Git repository root>/artifacts`, or `artifacts` next to the project outside a Git repository |

All build output goes to one `artifacts/` folder, in `bin/`, `obj/` and `publish/` subfolders, instead of `bin/` and `obj/` in every project.

### Project

| Property | Default |
| --- | --- |
| `Version` | `0.0.0.0-pre` when not set |
| `NeutralLanguage` | `en` |

The SDKs don't set who a project belongs to: `Company`, `Authors`, `Copyright`, the package ID prefix and the package icon are yours to set. Put them in a `Directory.Build.props` at the root of your repository:

```xml
<Project>
  <PropertyGroup>
    <Company>Acme</Company>
    <Authors>Acme</Authors>
    <Copyright>© Acme Inc.</Copyright>
    <PackageIdPrefix>acme.</PackageIdPrefix>
  </PropertyGroup>
</Project>
```

### C#

| Property | Default |
| --- | --- |
| `LangVersion` | `latest` |
| `Nullable` | `enable` |
| `ImplicitUsings` | `enable` |
| `AllowUnsafeBlocks` | `true` |
| `GenerateDocumentationFile` | `true`. Public types and members need XML documentation |
| `MSBuildTreatWarningsAsErrors` | `true` |

### Compilation

| Property | Default |
| --- | --- |
| `PublishAot` | `true` for executables in Release: `dotnet publish` compiles to native code |
| `OptimizationPreference` | `Speed` for executables in Release |
| `EnableAotAnalyzer`, `EnableTrimAnalyzer`, `EnableSingleFileAnalyzer` | `true` for executables in every configuration |
| `IsAotCompatible` | `true` for libraries that target .NET 8 or later |

See [Debug and Release](getting-started.md#debug-and-release).

### Platform

Properties that describe the computer doing the build, for use in your own conditions:

| Property | Value |
| --- | --- |
| `IsWindows`, `IsMacOS`, `IsLinux`, `IsFreeBSD` | `true` for the current operating system |
| `Architecture` | The CPU architecture in lowercase: `x64`, `arm64`, ... |
| `Is32Bit`, `Is64Bit` | From `Architecture` |
| `DefineConstants` | Adds `WINDOWS`, `MACOS`, `LINUX` or `FREEBSD`, for `#if` in C# |

```xml
<ItemGroup Condition=" '$(IsWindows)' == 'true' ">
  <None Include="native/windows/*.dll" CopyToOutputDirectory="PreserveNewest" />
</ItemGroup>
```

### Code analysis

| Property | Default |
| --- | --- |
| `IsEnabledAnalyzers` | `true`. Set to `false` to turn off everything in this table |
| `EnableNETAnalyzers`, `EnforceCodeStyleInBuild` | `true` |
| `AnalysisMode`, `AnalysisLevel` | `all`, `latest`: every .NET analyzer rule |
| `TreatWarningsAsErrors` | `true` |

The code style rules are in [`CodeAnalysis.globalconfig`](../src/cs/production/Sdk/CodeAnalysis/CodeAnalysis.globalconfig). They follow StyleCop's conventions using the analyzers built into .NET, so StyleCop isn't needed.

To require a header, such as a copyright notice, at the top of every C# file, set `file_header_template` in your `.editorconfig`. Files without it then fail the build:

```ini
[*.cs]
file_header_template = Copyright (c) Acme Inc. All rights reserved.
```

### Code coverage

| Property | Default |
| --- | --- |
| `IsEnabledCodeCoverage` | Not set. Set to `false` to exclude the whole assembly from coverage reports with `[ExcludeFromCodeCoverage]` |

### NuGet

| Property | Default |
| --- | --- |
| `IsPackable` | `false`. Set to `true` in projects you publish as packages |
| `PackageOutputPath` | `<Git repository root>/nupkg`, or `nupkg` next to the project outside a Git repository |
| `PackageIdPrefix` | Not set. Set it, for example to `acme.`, to make every package ID that isn't set explicitly `acme.<AssemblyName>` |
| `RepositoryType` | `git` |

## bottlenoselabs.Sdk.WebApp

Wraps `Microsoft.NET.Sdk.Web`. See [Web apps](web-apps.md).

| Property | Default |
| --- | --- |
| `EnableRequestDelegateGenerator`, `EnableConfigurationBindingGenerator` | `true` in every configuration, so minimal APIs and configuration binding pass the NativeAOT analyzers in Debug too |

## bottlenoselabs.Sdk.GameApp

Wraps `Microsoft.NET.Sdk`. See [Games](games.md).

| Property | Default |
| --- | --- |
| `OutputType` | `Exe` in Debug; `WinExe` in Release, so no console window opens on Windows |
| `TargetFramework` | `net<version>` from the .NET SDK in `global.json`, when the project sets none |
| `InvariantGlobalization` | `true` |
| `GameAssetsDirectory` | `Assets`. Copied next to the executable on build and publish |
| `GameAppIcon` | `icon.png` next to the project, or a neutral game controller icon |
| `ApplicationManifest` | A Windows manifest: per-monitor DPI awareness, long paths, UTF-8 |
| `IsEnabledPlatformPackaging` | `true`: publishing makes `MyGame.app` on macOS and `MyGame.AppDir` on Linux |
| `GameAppDisplayName` | `$(Product)` |
| `GameAppBundleIdentifier` | `com.<company>.<assembly name>` in lowercase, or `com.<assembly name>` when `Company` is not set |
| `GameAppMinimumMacOSVersion` | `15.0` |
| `IsEnabledPublishDebugSymbols` | Not set: debug symbols are left out of the published game. Set to `true` to publish them |
| `IsEnabledRuntimeMarshalling` | Not set: the assembly has `[DisableRuntimeMarshalling]`. Set to `true` to turn runtime marshalling back on |
| `PublishDocumentationFile`, `PublishReferencesDocumentationFiles` | `false` |
