# OPI Image Generator

This repository uses GitHub Actions to build Armbian images for supported Orange Pi boards.

## What the workflow does

The workflow in [.github/workflows/build.yml](.github/workflows/build.yml) runs the Armbian build action and produces image files for the configured target board.

This workflow builds for:
- "orangepi5-max"
- "orangepi5-plus"
- "orangepi5"
- "orangepi5b"
- "orangepi5pro"
- "rock-5c"

It builds images using the following settings:

- Armbian release: `trixie`
- Target: `build`
- UI: `minimal`

> [!IMPORTANT]
> The Armbian build system does not provide a way to produce reproducible builds. Use a tagged release to create images that can be used as fixed basis for photon-image-modifier.

## How to create an image

### 1. Push changes to the main branch

Pushing to `main` triggers a new build automatically. Images will be uploaded to the `Dev` tag and marked as pre-release. To keep the Dev tag clean, and consistent with HEAD, old assets that are stored in the Dev tag are deleted before the new images are uploaded.

### 2. Run the workflow manually

You can also start a build from the GitHub Actions tab:

1. Open the repository on GitHub.
2. Go to the Actions tab.
3. Select the `Build Armbian Images` workflow.
4. Click `Run workflow`.
5. Choose the branch and start the run.

### 3. Create a release

Creating a release will also trigger the workflow. Release builds are marked as a non-prerelease, while regular branch builds are marked as prerelease builds.
