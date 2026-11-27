# Web apps

`bottlenoselabs.Sdk.WebApp` is the SDK for ASP.NET Core web apps. It wraps `Microsoft.NET.Sdk.Web`, so everything you know about ASP.NET Core still applies, and adds the [settings every Bottlenose Labs SDK has](reference.md).

```xml
<Project Sdk="bottlenoselabs.Sdk.WebApp">

  <PropertyGroup>
    <TargetFramework>net11.0</TargetFramework>
  </PropertyGroup>

</Project>
```

## NativeAOT

Release publishes compile the web app to native code with NativeAOT. It starts in milliseconds and uses less memory than a JIT-compiled app, which matters most when you pay for memory or scale to zero.

NativeAOT has one big rule: no code generation at runtime and no reflection over types the compiler can't see. In practice:

| Works | Doesn't work |
| --- | --- |
| Minimal APIs (`app.MapGet`, `app.MapPost`, ...) | MVC controllers |
| `WebApplication.CreateSlimBuilder` | Razor Pages and Blazor Server |
| `System.Text.Json` with a `JsonSerializerContext` | Reflection-based JSON serialization |
| Configuration binding (`builder.Configuration.Get<T>()`) | Most of Entity Framework Core |
| Dapper with its AOT support, or raw ADO.NET | Libraries that build code at runtime |

You don't have to remember this list: the NativeAOT analyzers are on in Debug too, so code that won't work with NativeAOT fails the build as you write it.

## JSON

Every type that goes in or out as JSON needs a line in a `JsonSerializerContext`, so the serializer is generated at build time instead of using reflection at runtime:

```csharp
using System.Text.Json.Serialization;

namespace MyWebApp;

[JsonSerializable(typeof(Greeting))]
[JsonSerializable(typeof(List<Greeting>))]
internal sealed partial class AppJsonSerializerContext : JsonSerializerContext;
```

Register it once in `Program.cs`:

```csharp
var builder = WebApplication.CreateSlimBuilder(args);
builder.Services.ConfigureHttpJsonOptions(options =>
    options.SerializerOptions.TypeInfoResolverChain.Insert(0, AppJsonSerializerContext.Default));
```

The `bl-webapp` template sets this up for you.

## What the SDK adds

ASP.NET Core only turns on its source generators for minimal APIs and configuration binding when you publish with NativeAOT. The SDK turns them on in every configuration (`EnableRequestDelegateGenerator`, `EnableConfigurationBindingGenerator`). Without them, minimal APIs would fail the NativeAOT analyzers in Debug.

## Publishing

```bash
dotnet publish ./src/cs/MyWebApp --runtime linux-x64
```

Publish on the operating system you deploy to: NativeAOT can't build a Linux executable on Windows or macOS. For a container, publish inside a Linux build image, or in CI on a Linux runner.
