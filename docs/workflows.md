# Reusable GitHub Actions workflows

This repository has reusable workflows for C# repositories. Call them from your own workflows instead of copying the steps, so fixes and upgrades reach every repository.

| Workflow | What it does |
| --- | --- |
| [`cs-build.yml`](#cs-buildyml) | Builds and tests on Windows, Linux and macOS |
| [`cs-game-publish.yml`](#cs-game-publishyml) | Publishes a game for each platform and uploads the builds |
| [`cs-release.yml`](#cs-releaseyml) | Releases NuGet packages to NuGet.org and creates a GitHub release |

## Pinning a version

Reference a workflow by a release tag of this repository:

```yaml
uses: bottlenoselabs/sdk/.github/workflows/cs-build.yml@v<version>
```

Use the same version as the SDKs in your `global.json`. The `bl-*` templates do this for you. Avoid `@main`: a change here would then reach your repository without you choosing to take it.

The workflows pin every action they use to a commit SHA, and Dependabot keeps those pins up to date.

## cs-build.yml

Builds a solution, runs its tests, and optionally runs a script, on each operating system.

```yaml
jobs:
  build-job:
    name: "Build"
    uses: "bottlenoselabs/sdk/.github/workflows/cs-build.yml@v<version>"
    with:
      path: "./src/cs"
```

| Input | Default | Description |
| --- | --- | --- |
| `path` | `.` | Solution, project or directory to build |
| `configuration` | `Release` | Build configuration |
| `runs-on` | `["windows-latest", "ubuntu-latest", "macos-latest"]` | JSON array of runner labels; one job runs on each |
| `global-json-file` | `global.json` | The `global.json` that pins the .NET SDK version |
| `test` | `true` | Run `dotnet test` after the build. Set to `false` while the solution has no test projects |
| `script` | | Bash commands to run after the build and tests, from the repository root |

## cs-game-publish.yml

Publishes a game with NativeAOT once per platform and uploads each build as an artifact. NativeAOT can only build for the operating system it runs on, so each platform runs on a runner of that operating system.

```yaml
jobs:
  publish-job:
    name: "Publish"
    uses: "bottlenoselabs/sdk/.github/workflows/cs-game-publish.yml@v<version>"
    with:
      project: "./src/cs/MyGame/MyGame.csproj"
      runtime-identifiers: '["win-x64", "osx-arm64", "linux-x64"]'
```

| Input | Default | Description |
| --- | --- | --- |
| `project` | (required) | The game's `.csproj` |
| `runtime-identifiers` | `["win-x64", "osx-arm64", "linux-x64"]` | JSON array of [runtime identifiers](https://learn.microsoft.com/dotnet/core/rid-catalog) to publish for |
| `runners` | `{}` | JSON object to change the runner for a runtime identifier, for example `{"linux-arm64": "my-arm-runner"}` |
| `artifact-name` | The project file name | Prefix of the artifact names |
| `version` | | Version to stamp on the game |
| `submodules` | `false` | Clone Git submodules: `true`, `false` or `recursive` |
| `global-json-file` | `global.json` | The `global.json` that pins the .NET SDK version |
| `pre-publish-script` | | Bash commands to run before publishing, from the repository root |
| `retention-days` | `14` | Days to keep the artifacts |

The default runners:

| Runtime identifier | Runner |
| --- | --- |
| `win-x64`, `win-arm64` | `windows-latest` (Arm64 is cross-compiled) |
| `osx-arm64`, `osx-x64` | `macos-latest` |
| `linux-x64` | `ubuntu-latest` |
| `linux-arm64` | `ubuntu-24.04-arm` |

Each artifact is named `<artifact-name>-<runtime identifier>` and holds one archive, so macOS and Linux executables keep their executable permission:

| Platform | Archive | Contains, with `bottlenoselabs.Sdk.GameApp` |
| --- | --- | --- |
| Windows | `.zip` | `MyGame.exe` and the assets |
| macOS | `.tar.gz` | `MyGame.app` |
| Linux | `.tar.gz` | `MyGame.AppImage` |

On Linux the workflow turns the published `MyGame.AppDir` into `MyGame.AppImage` with [appimagetool](https://github.com/AppImage/appimagetool). The tool and its runtime are pinned to fixed releases and checked against their SHA-256 digests before they run.

On a private repository, macOS minutes count ten times against your GitHub Actions allowance, and the Arm64 runners need a paid plan. Publish for fewer platforms on pull requests if that matters to you.

## cs-release.yml

Packs NuGet packages, pushes them to NuGet.org, and creates a tagged GitHub release. It only runs from the default branch, because packages on NuGet.org can't be deleted.

Call it from a workflow you run by hand:

```yaml
name: "Release"

on:
  workflow_dispatch:
    inputs:
      pre-release:
        type: boolean
        default: true
      version:
        type: string
        default: ""

jobs:
  release-job:
    name: "Release"
    uses: "bottlenoselabs/sdk/.github/workflows/cs-release.yml@v<version>"
    permissions:
      contents: write   # create the tag and the GitHub release
      id-token: write   # NuGet trusted publishing
    with:
      path: "./src/cs"
      pre-release: ${{ inputs.pre-release }}
      version: ${{ inputs.version }}
    secrets:
      NUGET_USER: ${{ secrets.NUGET_USER }}
```

| Input | Default | Description |
| --- | --- | --- |
| `path` | `.` | Solution, project or directory to pack |
| `global-json-file` | `global.json` | The `global.json` that pins the .NET SDK version |
| `pre-release` | `true` | Mark the GitHub release as a pre-release. A generated version gets an `-rc` suffix |
| `version` | The date, for example `2026.11.27` | The version. A custom pre-release version needs its own suffix, for example `1.0.0-rc.1` |

The `version` output is the version that was released.

### Setting up NuGet.org

The workflow uses [NuGet trusted publishing](https://learn.microsoft.com/nuget/nuget-org/trusted-publishing): GitHub proves to NuGet.org which repository and workflow are publishing, so there is no long-lived API key to store or leak.

1. On NuGet.org, open your account's **Trusted Publishing** page and add a policy for your repository. For the workflow file, enter the file name of **your** release workflow, for example `release.yml`.
2. In your repository, add a secret named `NUGET_USER` with your NuGet.org user name, the account that owns the policy.
3. Run the release workflow from the **Actions** tab.

If the login step fails with a policy mismatch, add a second policy with the workflow file `cs-release.yml`. NuGet.org's documentation doesn't say which file name it checks when a reusable workflow publishes.
