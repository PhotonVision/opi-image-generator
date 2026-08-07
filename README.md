# OPI Image Generator

This repository uses GitHub Actions to build Armbian images for supported Orange Pi boards.

## What the workflow does

The workflow in [.github/workflows/build.yml](.github/workflows/build.yml) runs the Armbian build action and produces image files for the configured target board.

By default, it builds an image for the Orange Pi 5 board using the following settings:

- Armbian release: `trixie`
- Target: `build`
- UI: `minimal`

### Note
The Armbian build system allows specification of `armbian_version`, but it will automatically increment the patch version by one from the one supplied.

## How to create an image

### 1. Push changes to the main branch

Pushing to `master` or `main` triggers a new build automatically. Images will be uploaded to the `Dev` tag and marked as pre-release.

### 2. Run the workflow manually

You can also start a build from the GitHub Actions tab:

1. Open the repository on GitHub.
2. Go to the Actions tab.
3. Select the `Build Armbian Images` workflow.
4. Click `Run workflow`.
5. Choose the branch and start the run.

### 3. Create a release

Creating a release will also trigger the workflow. Release builds are marked as a non-prerelease, while regular branch builds are marked as prerelease builds.
