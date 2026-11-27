# MyWebApp

A C# web app on [`bottlenoselabs.Sdk.WebApp`](https://github.com/bottlenoselabs/sdk).

## Develop

```bash
dotnet run --project ./src/cs/MyWebApp
```

## Publish

```bash
dotnet publish ./src/cs/MyWebApp --runtime linux-x64
```

Release builds are compiled to native code with NativeAOT. That means minimal APIs and source-generated JSON: add each type you return to `AppJsonSerializerContext`. MVC, Razor Pages and most of Entity Framework Core are not NativeAOT-compatible.
