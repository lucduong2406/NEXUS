#!/bin/sh

# -----------------------------------------------------------------------------
# 1) Define environment variables and colors for terminal output.
# -----------------------------------------------------------------------------
NEXUS_HOME="$HOME/.nexus"
BIN_DIR="$NEXUS_HOME/bin"
GREEN='\033[1;32m'
ORANGE='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m'  # No Color

# Ensure the $NEXUS_HOME and $BIN_DIR directories exist.
[ -d "$NEXUS_HOME" ] || mkdir -p "$NEXUS_HOME"
[ -d "$BIN_DIR" ] || mkdir -p "$BIN_DIR"

# -----------------------------------------------------------------------------
# 2) Display a message if we're interactive (NONINTERACTIVE is not set) and the
#    $NODE_ID is not a 28-character ID. This is for Testnet II info.
# -----------------------------------------------------------------------------
if [ -z "$NONINTERACTIVE" ] && [ "${#NODE_ID}" -ne "28" ]; then
    echo ""
    echo "${GREEN}Testnet III is now live!${NC}"
    echo ""
fi

# -----------------------------------------------------------------------------
# 3) Prompt the user to agree to the Nexus Beta Terms of Use if we're in an
#    interactive mode (i.e., NONINTERACTIVE is not set) and no config.json file exists.
#    We explicitly read from /dev/tty to ensure user input is requested from the
#    terminal rather than the script's standard input.
# -----------------------------------------------------------------------------
# Đã sửa: Tự động đồng ý mà không prompt, giả định đồng ý nếu config chưa tồn tại.

# -----------------------------------------------------------------------------
# 4) Determine the platform and architecture
# -----------------------------------------------------------------------------
# Đã sửa: Mặc định là linux x86_64, không detect từ uname.
PLATFORM="linux"
ARCH="x86_64"
BINARY_NAME="nexus-network-linux-x86_64"

# -----------------------------------------------------------------------------
# 5) Download latest release binary
# -----------------------------------------------------------------------------
# Đã sửa: Sử dụng cách lấy tag và xây dựng URL để tránh lỗi parsing JSON bằng awk.
TAG=$(curl -s https://api.github.com/repos/nexus-xyz/nexus-cli/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$TAG" ]; then
    echo "${RED}Could not retrieve latest release tag for $PLATFORM-$ARCH${NC}"
    echo "Please build from source:"
    echo "  git clone https://github.com/nexus-xyz/nexus-cli.git"
    echo "  cd nexus-cli/clients/cli"
    echo "  cargo build --release"
    exit 1
fi

LATEST_RELEASE_URL="https://github.com/nexus-xyz/nexus-cli/releases/download/$TAG/$BINARY_NAME"

# Kiểm tra nếu URL tồn tại (optional, để match lỗi gốc)
HTTP_STATUS=$(curl -s -I -L "$LATEST_RELEASE_URL" | grep '^HTTP/' | awk '{print $2}')
if [ "$HTTP_STATUS" != "200" ] && [ "$HTTP_STATUS" != "302" ]; then  # 302 cho redirect
    echo "${RED}Could not find a precompiled binary for $PLATFORM-$ARCH at $LATEST_RELEASE_URL${NC}"
    echo "Please build from source:"
    echo "  git clone https://github.com/nexus-xyz/nexus-cli.git"
    echo "  cd nexus-cli/clients/cli"
    echo "  cargo build --release"
    exit 1
fi

echo "Downloading latest release for $PLATFORM-$ARCH..."
curl -L -o "$BIN_DIR/nexus-network" "$LATEST_RELEASE_URL"
chmod +x "$BIN_DIR/nexus-network"
ln -s "$BIN_DIR/nexus-network" "$BIN_DIR/nexus-cli"
chmod +x "$BIN_DIR/nexus-cli"

# -----------------------------------------------------------------------------
# 6) Add $BIN_DIR to PATH if not already present
# -----------------------------------------------------------------------------
case "$SHELL" in
    */bash)
        PROFILE_FILE="$HOME/.bashrc"
        ;;
    */zsh)
        PROFILE_FILE="$HOME/.zshrc"
        ;;
    *)
        PROFILE_FILE="$HOME/.profile"
        ;;
esac

# Only append if not already in PATH
if ! echo "$PATH" | grep -q "$BIN_DIR"; then
    if ! grep -qs "$BIN_DIR" "$PROFILE_FILE"; then
        echo "" >> "$PROFILE_FILE"
        echo "# Add Nexus CLI to PATH" >> "$PROFILE_FILE"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$PROFILE_FILE"
        echo "${GREEN}Updated PATH in $PROFILE_FILE${NC}"
    fi
fi

echo ""
echo "${GREEN}Installation complete!${NC}"
echo "Restart your terminal or run the following command to update your PATH:"
echo "  source $PROFILE_FILE"
echo ""
echo "${ORANGE}To get your node ID, visit: https://app.nexus.xyz/nodes${NC}"
echo ""
echo "Register your user to begin linked proving with the Nexus CLI by: nexus-cli register-user --wallet-address <WALLET_ADDRESS>"
echo "Or follow the guide at https://docs.nexus.xyz/layer-1/testnet/cli-node"
