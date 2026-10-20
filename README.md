# clutta CLI releases

This repository hosts binary releases of the [Clutta](https://clutta.io) CLI, an infrastructure incident diagnosis tool. The source code is maintained in a private repository. This repo contains compiled release binaries only.

## Install

**macOS and Linux**

```sh
curl -fsSL https://clutta.io/install | sh
```

**Windows (PowerShell)**

```powershell
iwr -useb https://clutta.io/install.ps1 | iex
```

Both installers select the latest stable release by default and verify the exact
artifact's SHA-256 checksum before replacing an existing installation. RCs require
an explicit `CLUTTA_VERSION`. Downloads or verification failures preserve the
existing binary.

Supported platforms: macOS (Apple Silicon and Intel), Linux (x86_64 and ARM64),
Windows (x86_64, using 64-bit Windows PowerShell 5.1 or PowerShell 7).

No elevation is needed for the default user-local directories. The shell installer
prints PATH setup instructions if needed. Windows updates the user's PATH unless
`CLUTTA_NO_PATH_UPDATE=1` is set. A blocked download is not proof of a false
positive: do not disable protection or add exclusions. Contact your security
administrator or Clutta support.

PowerShell installation failures throw a catchable error without exiting the
interactive terminal. For automation, run the downloaded script with
`powershell -NoProfile -File install.ps1` or `pwsh -NoProfile -File install.ps1`
and check its exit status.

## Installer validation

The installer workflow runs deterministic failure tests and installs the public
Windows binary on a Windows runner with both PowerShell versions. It verifies
the installed path, version, checksum and CLI execution without Clutta credentials.
Test-owned installation directories are removed and persistent PATH is unchanged.

Scheduled runs additionally test the live `clutta.io/install.ps1` endpoint.
Before merging installer changes, CI uses the candidate script, not the old
website copy. After merge, manually dispatch with `live=true` to verify rollout.
The website caches upstream scripts for five minutes, so a merge does not prove
that the live response has refreshed.

Local shell checks: `python3 -m unittest discover -s tests -p 'test_*.py' -v`.
Windows contract checks: `./tests/windows-contract.ps1`.

## Manual install

If you prefer to download the binary directly, grab it from the [latest release](../../releases/latest) along with `sha256sums.txt`, verify the checksum, and move it into your PATH.

```sh
# macOS Apple Silicon
VERSION=v0.0.1
curl -fsSL https://github.com/sefastech/clutta-cli-releases/releases/download/${VERSION}/clutta-darwin-arm64 -o clutta
curl -fsSL https://github.com/sefastech/clutta-cli-releases/releases/download/${VERSION}/sha256sums.txt -o sha256sums.txt

# verify before running
shasum -a 256 clutta

chmod +x clutta
mv clutta /usr/local/bin/clutta
```

## Installing a specific version

Set `CLUTTA_VERSION` before running the install script to pin to a particular release.

```sh
export CLUTTA_VERSION=v0.0.1
curl -fsSL https://clutta.io/install | sh
```

## Rollback

If you need to roll back, install the previous version explicitly using the commands above with the version you want.

## Uninstall

```sh
rm $(which clutta)
```

## Verifying a release

Every release ships a `sha256sums.txt` alongside the binaries. To verify a binary you downloaded manually, run the appropriate command for your platform and compare the output against the matching line in `sha256sums.txt`.

```sh
# macOS
shasum -a 256 clutta-darwin-arm64

# Linux
sha256sum clutta-linux-amd64
```

## License

MIT. See [LICENSE](LICENSE).
