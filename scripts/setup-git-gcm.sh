#!/usr/bin/env bash
set -e

echo "=== Git Credential Manager Setup for Arch Linux ==="

# Ensure dependencies
echo "[1/6] Installing required packages..."
sudo pacman -S --needed --noconfirm git git-credential-manager-bin libsecret less

# Configure Git Credential Manager
echo "[2/6] Configuring Git Credential Manager..."
git-credential-manager configure

# Clean up any previous credential helpers
echo "[3/6] Cleaning old Git credential helpers..."
git config --global --unset-all credential.helper || true

# Set the correct helper
echo "[4/6] Setting Git Credential Manager as helper..."
git config --global credential.helper manager
git config --global credential.interactive always
git config --global credential.credentialStore secretservice

# Optional global Git identity setup (edit as needed)
echo "[5/6] Setting your global Git identity..."
read -p "Enter your Git user.name: " GIT_NAME
read -p "Enter your Git user.email: " GIT_EMAIL
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Enable Secret Service daemon (GNOME / KWallet)
echo "[6/6] Ensuring Secret Service is running..."
if command -v gnome-keyring-daemon >/dev/null 2>&1; then
    systemctl --user enable --now gnome-keyring-daemon
    echo "✔ Using GNOME Keyring (Secret Service)."
elif command -v kwalletd5 >/dev/null 2>&1; then
    systemctl --user enable --now kwalletd5
    echo "✔ Using KDE KWallet (Secret Service)."
else
    echo "⚠ No Secret Service detected — install GNOME Keyring or KWallet for secure credential storage."
fi

# Display result
echo
echo "=== ✅ Git Credential Manager configured successfully! ==="
echo
echo "Test with: git clone https://github.com/<your-username>/<repo>"
echo "A browser window should open for authentication, and credentials will be stored securely."
echo
git config --global --list | grep credential
