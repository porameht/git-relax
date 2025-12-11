#!/bin/sh
set -e

# Git Relax Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/porameht/git-relax/main/install.sh | sh

REPO="porameht/git-relax"
INSTALL_DIR="${HOME}/.local/bin"
BINARY_NAME="git-relax"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info() {
    printf "${CYAN}INFO${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}✓${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}WARN${NC} %s\n" "$1"
}

error() {
    printf "${RED}ERROR${NC} %s\n" "$1"
    exit 1
}

# Detect OS
detect_os() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case "$OS" in
        linux*) OS="linux" ;;
        darwin*) OS="darwin" ;;
        mingw*|msys*|cygwin*) OS="windows" ;;
        *) error "Unsupported OS: $OS" ;;
    esac
}

# Detect Architecture
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|amd64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        armv7l) ARCH="armv7" ;;
        *) error "Unsupported architecture: $ARCH" ;;
    esac
}

# Get target triple
get_target() {
    case "${OS}-${ARCH}" in
        linux-x86_64) TARGET="x86_64-unknown-linux-gnu" ;;
        linux-aarch64) TARGET="aarch64-unknown-linux-gnu" ;;
        darwin-x86_64) TARGET="x86_64-apple-darwin" ;;
        darwin-aarch64) TARGET="aarch64-apple-darwin" ;;
        windows-x86_64) TARGET="x86_64-pc-windows-msvc" ;;
        *) error "Unsupported platform: ${OS}-${ARCH}" ;;
    esac
}

# Get latest version
get_latest_version() {
    VERSION=$(curl -sL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | cut -d'"' -f4)
    if [ -z "$VERSION" ]; then
        error "Failed to get latest version"
    fi
}

# Download and install
install() {
    info "Installing git-relax..."

    detect_os
    detect_arch
    get_target
    get_latest_version

    info "OS: $OS"
    info "Architecture: $ARCH"
    info "Target: $TARGET"
    info "Version: $VERSION"

    # Create install directory
    mkdir -p "$INSTALL_DIR"

    # Download URL
    if [ "$OS" = "windows" ]; then
        ARCHIVE_NAME="${BINARY_NAME}-${TARGET}.zip"
    else
        ARCHIVE_NAME="${BINARY_NAME}-${TARGET}.tar.gz"
    fi

    URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARCHIVE_NAME}"

    info "Downloading from: $URL"

    # Download and extract
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"

    if ! curl -fsSL "$URL" -o "$ARCHIVE_NAME"; then
        error "Failed to download $URL"
    fi

    if [ "$OS" = "windows" ]; then
        unzip -q "$ARCHIVE_NAME"
    else
        tar xzf "$ARCHIVE_NAME"
    fi

    # Install binary
    if [ "$OS" = "windows" ]; then
        mv "${BINARY_NAME}.exe" "${INSTALL_DIR}/"
    else
        mv "$BINARY_NAME" "${INSTALL_DIR}/"
        chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    fi

    # Cleanup
    cd - > /dev/null
    rm -rf "$TEMP_DIR"

    success "Installed to ${INSTALL_DIR}/${BINARY_NAME}"

    # Check if in PATH
    case ":$PATH:" in
        *":${INSTALL_DIR}:"*) ;;
        *)
            warn "${INSTALL_DIR} is not in your PATH"
            echo ""
            echo "Add this to your shell profile (~/.zshrc, ~/.bashrc, etc.):"
            echo ""
            echo "  export PATH=\"\$PATH:${INSTALL_DIR}\""
            echo ""
            ;;
    esac

    echo ""
    success "Installation complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Set up your API key:"
    echo "     export OPENAI_API_KEY=\"sk-...\""
    echo "     # or"
    echo "     export ANTHROPIC_API_KEY=\"sk-ant-...\""
    echo ""
    echo "  2. For GitHub features, set:"
    echo "     export GITHUB_TOKEN=\"ghp_...\""
    echo ""
    echo "  3. Run: git-relax --help"
    echo ""
}

# Run installer
install
