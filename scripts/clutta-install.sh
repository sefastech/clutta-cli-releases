#!/bin/bash

# clutta-install.sh
# This script installs or updates clutta-cli on macOS and Linux systems.

# Function to display usage information
usage() {
    echo "Usage: $0 [-v version]"
    echo "  -v version   Specify the version to install (e.g., v1.0.0). Defaults to the latest version if not specified."
    exit 1
}

# Parse command-line options
VERSION=""
while getopts "v:" opt; do
    case ${opt} in
        v)
            VERSION=$OPTARG
            ;;
        *)
            usage
            ;;
    esac
done

# Determine the platform
OS=$(uname -s)
ARCH=$(uname -m)

# Normalize OS name
case "$OS" in
    Linux) OS="linux" ;;
    Darwin) OS="macos" ;;
    *) echo "Unsupported OS: $OS"; exit 1 ;;
esac

# Normalize architecture name
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Set the GitHub repo and fetch the latest version if not provided
REPO="sefastech/clutta-cli-releases"
if [[ -z "$VERSION" ]]; then
    echo "Fetching the latest version..."
    VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
    if [[ -z "$VERSION" ]]; then
        echo "Failed to fetch the latest version."
        exit 1
    fi
fi

# Construct the download URL
FILENAME="clutta-$OS-$ARCH"
URL="https://github.com/$REPO/releases/download/$VERSION/$FILENAME"

# Download the binary
echo "Downloading clutta version $VERSION for $OS/$ARCH..."
curl -L -o clutta "$URL"
if [[ $? -ne 0 ]]; then
    echo "Download failed."
    exit 1
fi

# Make the binary executable
chmod +x clutta

# Move the binary to /usr/local/bin (requires sudo)
echo "Installing clutta to /usr/local/bin..."
sudo mv clutta /usr/local/bin/
if [[ $? -ne 0 ]]; then
    echo "Failed to move clutta to /usr/local/bin."
    exit 1
fi

echo "clutta version $VERSION installed successfully."
