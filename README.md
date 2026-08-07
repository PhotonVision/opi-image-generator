# OPI Image Generator

This repository uses GitHub Actions to build Armbian images for supported Orange Pi boards.

## What the workflow does

The workflow in [.github/workflows/build.yml](.github/workflows/build.yml) runs the Armbian build action and produces image files for the configured target board.

By default, it builds an image for the Orange Pi 5 board using the following settings:

- Armbian release: `trixie`
- Armbian version: `26.5.3`
- Target: `build`
- UI: `minimal`

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

## Where the output goes

The workflow writes images to the build output directory used by Armbian:

- `build/output/images/`

If the build succeeds, the generated image archive is available from the workflow run artifacts and the build output directory.

## Customizing the build

You can change which boards are built by editing the matrix in [.github/workflows/build.yml](.github/workflows/build.yml).

The board list is currently configured under the `matrix.board` section. Uncomment the boards you want to build, or replace the current board entry with another supported target.

You can also adjust:

- the Armbian release version
- the target board
- the release type and tagging behavior
- the artifact retention settings

## Notes

- The workflow uses the GitHub Actions runner and the Armbian build action.
- If a build fails, the workflow still attempts to upload any generated `.img.xz` files as an artifact.
