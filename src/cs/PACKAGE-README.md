# bottlenoselabs/sdk

MSBuild SDKs, project templates, and reusable GitHub Actions workflows for C#: modern defaults, strict code analysis, and native compilation with NativeAOT for Release builds.

| Package | For | Wraps |
| --- | --- | --- |
| `bottlenoselabs.Sdk` | Libraries, console apps, tools | `Microsoft.NET.Sdk` |
| `bottlenoselabs.Sdk.WebApp` | ASP.NET Core web apps | `Microsoft.NET.Sdk.Web` |
| `bottlenoselabs.Sdk.GameApp` | Games: assets, icons, and `.exe`, `.app` and AppImage output | `Microsoft.NET.Sdk` |
| `bottlenoselabs.Templates` | `dotnet new` templates: `bl-game`, `bl-webapp`, `bl-lib` | |

## Use

Pin the SDK in `global.json`:

```json
{
  "msbuild-sdks": {
    "bottlenoselabs.Sdk.GameApp": "<version>"
  }
}
```

Then use it in your project file:

```xml
<Project Sdk="bottlenoselabs.Sdk.GameApp" />
```

Or start a new repository from a template:

```bash
dotnet new install bottlenoselabs.Templates::<version>
dotnet new bl-game --name MyGame
```

## Documentation

- [Getting started](https://github.com/bottlenoselabs/sdk/blob/main/docs/getting-started.md)
- [Games](https://github.com/bottlenoselabs/sdk/blob/main/docs/games.md)
- [Web apps](https://github.com/bottlenoselabs/sdk/blob/main/docs/web-apps.md)
- [Workflows](https://github.com/bottlenoselabs/sdk/blob/main/docs/workflows.md)
- [Reference](https://github.com/bottlenoselabs/sdk/blob/main/docs/reference.md)

Source, issues and releases: [github.com/bottlenoselabs/sdk](https://github.com/bottlenoselabs/sdk). MIT license.
