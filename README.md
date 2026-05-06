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

Both installers detect your architecture, download the correct binary, verify the SHA-256 checksum, and place the binary in your PATH.

Supported platforms: macOS (Apple Silicon and Intel), Linux (x86\_64), Windows (x86\_64).

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
