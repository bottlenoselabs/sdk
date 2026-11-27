# MyLibrary

A C# library on [`bottlenoselabs.Sdk`](https://github.com/bottlenoselabs/sdk), published to NuGet.org as `bottlenoselabs.MyLibrary`.

## Develop

```bash
dotnet build ./src/cs
```

## Release

1. On nuget.org, add a trusted publishing policy for this repository and the `release.yml` workflow.
2. Add a `NUGET_USER` repository secret with the nuget.org user name that owns the policy.
3. Run the "Release" workflow from the Actions tab.
