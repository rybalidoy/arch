#!/bin/bash
# Exit immediately on error
set -e

echo "=============================================="
echo "🚀 Setting up CPU Power Management & CoolerControl"
echo "=============================================="

# ----------------------------------------------
# CPU Power Control (cpupower + power profiles)
# ----------------------------------------------
echo "📦 Installing cpupower and tools..."
sudo pacman -S --needed --noconfirm linux-tools cpupower

echo "⚙️ Configuring cpupower..."
echo balance_performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
sudo systemctl enable --now cpupower

echo "📦 Installing power-profiles-daemon..."
sudo pacman -S --needed --noconfirm power-profiles-daemon

echo "⚙️ Enabling and starting power-profiles-daemon..."
sudo systemctl enable --now power-profiles-daemon

echo "🔎 Checking available power profiles..."
powerprofilesctl || echo "Run 'powerprofilesctl' manually to check available profiles."

# ----------------------------------------------
# CoolerControl (Fan Management)
# ----------------------------------------------
echo "=============================================="
echo "🧊 Installing CoolerControl & Sensor Drivers"
echo "=============================================="

# --- AUR Helper ---
if ! command -v yay &>/dev/null; then
  echo "📦 yay not found. Installing yay..."
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
fi

# --- Base tools ---
echo "📦 Installing dependencies..."
sudo pacman -S --needed --noconfirm lm_sensors liquidctl dkms

# --- CoolerControl ---
echo "📦 Installing CoolerControl..."
yay -S --noconfirm coolercontrol

echo "⚙️ Enabling CoolerControl service..."
sudo systemctl enable --now coolercontrold

# --- Sensor Detection ---
echo "🔍 Detecting sensors..."
sudo sensors-detect --auto || true

# ----------------------------------------------
# nct6775 Setup (Fan/Temperature Sensor Module)
# ----------------------------------------------
echo "=============================================="
echo "🔧 Setting up nct6775 fan sensor module"
echo "=============================================="

# Check kernel for module support
if ! modinfo nct6775 &>/dev/null; then
  echo "⚠️ nct6775 module not found in kernel. Installing from AUR (dkms)..."
  yay -S --noconfirm nct6775-dkms || {
    echo "❌ Failed to install nct6775-dkms. Please check AUR availability."
    exit 1
  }
else
  echo "✅ nct6775 module available in kernel."
fi

# Try to load module
echo "🔧 Loading nct6775 module..."
if sudo modprobe nct6775; then
  echo "✅ nct6775 module loaded successfully."
else
  echo "⚠️ Could not load nct6775 module. Checking dmesg for hints..."
  dmesg | grep nct6775 || true
fi

# Persist module across reboots
if [ ! -f /etc/modules-load.d/nct6775.conf ]; then
  echo "📝 Adding nct6775 to autoload..."
  echo nct6775 | sudo tee /etc/modules-load.d/nct6775.conf
fi

# Restart services
echo "🔁 Restarting CoolerControl daemon..."
sudo systemctl restart coolercontrold

# Check status
echo "=============================================="
echo "✅ Setup complete!"
echo
echo "Next steps:"
echo "  • Run 'sensors' → verify CPU & fan readings"
echo "  • Run 'coolercontrol-cli detect' → detect devices"
echo "  • Launch 'coolercontrol' GUI"
echo "=============================================="

# Restore CoolerControl fan profiles if available
if [ -f "$HOME/dotfiles/coolercontrol/coolercontrol-backup.sh" ]; then
  echo "🧊 Restoring CoolerControl profiles from dotfiles..."
  bash "$HOME/dotfiles/coolercontrol/coolercontrol-backup.sh" restore
else
  echo "⚠️ No CoolerControl restore script found in ~/dotfiles/coolercontrol/"
fi
