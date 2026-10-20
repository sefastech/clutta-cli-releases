#!/bin/sh
# Clutta CLI installer
#
# Usage:
#   curl -fsSL https://clutta.io/install | sh
#
# Environment variables (all optional):
#   CLUTTA_VERSION      — install a specific version, e.g.:
#                           export CLUTTA_VERSION=v0.0.1
#                           curl -fsSL https://clutta.io/install | sh
#                         defaults to the latest published release
#   CLUTTA_INSTALL_DIR  — install to a custom directory
#                         defaults to /usr/local/bin

set -e

REPO="sefastech/clutta-cli-releases"
BINARY="clutta"

# ── Platform detection ────────────────────────────────────────────────────────

OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
  Darwin) OS="darwin" ;;
  Linux)  OS="linux"  ;;
  *)
    echo "error: unsupported operating system: $OS" >&2
    echo "" >&2
    echo "       On Windows, install clutta from PowerShell:" >&2
    echo "       iwr -useb https://clutta.io/install.ps1 | iex" >&2
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64)        ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
  *)
    echo "error: unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

ASSET="${BINARY}-${OS}-${ARCH}"

# ── Version resolution ────────────────────────────────────────────────────────

if [ -n "$CLUTTA_VERSION" ]; then
  VERSION="$CLUTTA_VERSION"
else
  # RCs require an explicit version override.
  VERSION=$(curl -fsSL --retry 3 --retry-delay 1 --retry-connrefused "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' \
    | head -n 1 \
    | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')

  if [ -z "$VERSION" ]; then
    echo "error: could not determine the latest version." >&2
    echo "       Check your internet connection or set CLUTTA_VERSION explicitly." >&2
    exit 1
  fi
  if ! printf '%s\n' "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+$'; then
    echo "error: no valid stable release was returned" >&2
    exit 1
  fi
fi

case "$VERSION" in
  *[!a-zA-Z0-9.-]*)
    echo "error: invalid characters in CLUTTA_VERSION" >&2
    exit 1
    ;;
esac
if ! printf '%s\n' "$VERSION" | grep -Eq '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$'; then
  echo "error: invalid CLUTTA_VERSION" >&2
  exit 1
fi

echo "Installing clutta ${VERSION} (${OS}/${ARCH})..."

# ── Download ──────────────────────────────────────────────────────────────────

BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"

# Use a temp directory so a failed install never leaves a partial binary on PATH.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading binary..."
if ! curl -fsSL --retry 3 --retry-delay 1 --retry-connrefused "${BASE_URL}/${ASSET}" -o "${TMP_DIR}/${BINARY}"; then
  echo "error: failed to download ${BASE_URL}/${ASSET}" >&2
  echo "       Check that version ${VERSION} exists at:" >&2
  echo "       https://github.com/${REPO}/releases" >&2
  exit 1
fi

echo "Downloading checksums..."
if ! curl -fsSL --retry 3 --retry-delay 1 --retry-connrefused "${BASE_URL}/sha256sums.txt" -o "${TMP_DIR}/sha256sums.txt"; then
  echo "error: failed to download sha256sums.txt" >&2
  exit 1
fi

# ── Checksum verification ─────────────────────────────────────────────────────

echo "Verifying checksum..."

# A missing download is a failure, not proof of an antivirus false positive.
if [ ! -s "${TMP_DIR}/${BINARY}" ]; then
  echo "error: the downloaded binary disappeared before it could be verified." >&2
  echo "       If security software blocked it, ask your administrator or" >&2
  echo "       Clutta support to investigate. Do not bypass endpoint protection." >&2
  exit 1
fi

# sha256sum is standard on Linux; macOS ships shasum instead.
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL=$(sha256sum "${TMP_DIR}/${BINARY}" | awk '{print $1}')
else
  ACTUAL=$(shasum -a 256 "${TMP_DIR}/${BINARY}" | awk '{print $1}')
fi

EXPECTED=$(awk -v asset="$ASSET" 'NF == 2 && ($2 == asset || $2 == "*" asset) {print $1}' "${TMP_DIR}/sha256sums.txt")

if ! printf '%s\n' "$EXPECTED" | grep -Eq '^[a-f0-9]{64}$' || [ "$(printf '%s\n' "$EXPECTED" | wc -l | tr -d ' ')" != 1 ]; then
  echo "error: expected one valid checksum entry for ${ASSET}" >&2
  exit 1
fi

if [ "$ACTUAL" != "$EXPECTED" ]; then
  echo "error: checksum verification failed — the download may be corrupted." >&2
  printf "  expected: %s\n" "$EXPECTED" >&2
  printf "  actual:   %s\n" "$ACTUAL" >&2
  exit 1
fi

echo "Checksum verified."

# ── Install ───────────────────────────────────────────────────────────────────

chmod +x "${TMP_DIR}/${BINARY}"

# Install location.
#
# By default Clutta installs to the user's local bin
# (${HOME}/.local/bin) — same pattern as rustup, nvm, mise, volta,
# pipx. This means:
#   - No sudo. No password prompts. No hangs when piped from curl.
#   - Works on every host whether the user has root or not.
#   - The user just adds ~/.local/bin to PATH once (we print the line).
#
# Operators who want a system-wide install set CLUTTA_INSTALL_DIR
# explicitly:
#
#   curl -fsSL https://clutta.io/install | CLUTTA_INSTALL_DIR=/usr/local/bin sudo -E sh
#
# (the sudo + -E lets the env var pass through; that path is for
# admins, not beta engineers.)
if [ -n "$CLUTTA_INSTALL_DIR" ]; then
  INSTALL_DIR="$CLUTTA_INSTALL_DIR"
else
  INSTALL_DIR="${HOME}/.local/bin"
fi
mkdir -p "$INSTALL_DIR"
mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "clutta ${VERSION} installed to ${INSTALL_DIR}/${BINARY}"

# Warn if the install directory is not on PATH.
case ":${PATH}:" in
  *":${INSTALL_DIR}:"*)
    # Already on PATH; nothing to do.
    ;;
  *)
    echo ""
    echo "note: ${INSTALL_DIR} is not on your PATH yet."
    echo "      Add this line to your shell profile (~/.bashrc, ~/.zshrc, or equivalent):"
    echo ""
    echo "      export PATH=\"${INSTALL_DIR}:\${PATH}\""
    echo ""
    echo "      Then reload the profile or open a new terminal."
    ;;
esac

echo ""
echo "Run 'clutta --help' to get started."
