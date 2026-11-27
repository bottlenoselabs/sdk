# bottlenoselabs/sdk

The foundation for C# development at [Bottlenose Labs](https://github.com/bottlenoselabs): MSBuild SDKs, project templates, and reusable GitHub Actions workflows. Open source under the [MIT license](LICENSE).

Change one line in your project file to get modern C# defaults, strict code analysis, and native compilation for Release builds:

```xml
<Project Sdk="bottlenoselabs.Sdk.GameApp" />
```

| Package | For | Wraps |
| --- | --- | --- |
| `bottlenoselabs.Sdk` | Libraries, console apps, tools | `Microsoft.NET.Sdk` |
| `bottlenoselabs.Sdk.WebApp` | ASP.NET Core web apps | `Microsoft.NET.Sdk.Web` |
| `bottlenoselabs.Sdk.GameApp` | Games | `Microsoft.NET.Sdk` |
| `bottlenoselabs.Templates` | `dotnet new` templates for new repositories | |

> [!NOTE]
> The packages are in pre-release. Find the latest version on [Releases](https://github.com/bottlenoselabs/sdk/releases) and use it for `<version>` below: pre-release versions must be named explicitly.

## What you get

- **Debug for prototyping, Release for shipping.** Debug builds use the JIT for fast iteration. Release publishes compile to native code with NativeAOT: instant startup, no JIT, and no IL to decompile.
- **Strict code analysis.** Every .NET analyzer rule, consistent code style, nullable reference types, and warnings as errors.
- **Games that ship.** An assets folder, an icon for every platform, and `dotnet publish` output in each platform's own format: a Windows `.exe`, a macOS `.app` and a Linux AppImage.
- **Web apps ready for NativeAOT.** Minimal APIs and source generators set up so problems show up in Debug, not at publish time.
- **CI in a few lines.** Reusable workflows that build on Windows, macOS and Linux, publish games for each platform, and release packages to NuGet.org.

## Quick start

```bash
dotnet new install bottlenoselabs.Templates@<version>
dotnet new bl-game --name MyGame        # or bl-webapp, bl-lib
cd MyGame
git init
dotnet run --project ./src/cs/MyGame
```

## Documentation

| Guide | What's in it |
| --- | --- |
| [Getting started](docs/getting-started.md) | Templates, adding an SDK to an existing project, Debug and Release |
| [Games](docs/games.md) | Assets, icons, publishing for Windows, macOS and Linux |
| [Web apps](docs/web-apps.md) | Writing ASP.NET Core code that works with NativeAOT |
| [Workflows](docs/workflows.md) | The reusable GitHub Actions workflows and releasing to NuGet.org |
| [Reference](docs/reference.md) | Every property the SDKs set, and how to change it |
| [Contributing](CONTRIBUTING.md) | How the SDKs work, testing, and releasing |
