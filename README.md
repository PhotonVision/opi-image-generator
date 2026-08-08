# OPI Image Generator

This repository uses GitHub Actions to build Armbian images for supported Orange Pi boards.

## What the workflow does

The workflow in [.github/workflows/build.yml](.github/workflows/build.yml) runs the Armbian build action and produces image files for the configured target board.

This workflow builds for:
- "orangepi5"
- "orangepi5b"
- "orangepi5pro"
- "orangepi5-max"
- "orangepi5-plus"
- "rock-5c"

It builds images using the following settings:

- Armbian release: `trixie`
- Target: `build`
- UI: `minimal`

> [!IMPORTANT]
> The Armbian build system does not provide a way to produce reproducible builds. Use a tagged release to create images that can be used as fixed basis for photon-image-modifier.

## Image creation:

### 1. Open or update a pull request

The workflow runs on pull requests and will produce image(s) that are stored as assets attached to the workflow action. These assets are retained for 7 days.

### 2. Merge a pull request to the main branch

Merging a pull request to `main` triggers a new build automatically. Images and associated files are uploaded to the `Dev` tag and marked as pre-release. To keep the Dev tag clean and consistent with HEAD, old assets that are stored in the Dev tag are deleted before the new images are uploaded.

### 3. Create a release

Creating a release triggers the workflow. When triggered by a tag, it will place all images and associated files in the assets of the tagged release. Release builds are marked as a non-prerelease and the newest release will be marked as latest.

### 4. Run the workflow manually

You can start a build from the GitHub Actions tab:

1. Open the repository on GitHub.
2. Go to the Actions tab.
3. Select the `Build Armbian Images` workflow.
4. Click `Run workflow`.
5. Choose the branch and start the run.
