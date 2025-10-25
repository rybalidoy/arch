#!/bin/bash
# ============================================================
# CoolerControl Backup + Restore Script
# Safe for Git repos (excludes restricted files)
# ============================================================

set -e

COOLER_DIR="$HOME/dotfiles/coolercontrol"
BACKUP_DIR="$COOLER_DIR/backup"
RESTORE_DIR="$COOLER_DIR/restore"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

mkdir -p "$BACKUP_DIR" "$RESTORE_DIR"

backup_configs() {
  echo "🧊 Backing up CoolerControl configuration..."
  mkdir -p "$BACKUP_DIR/$TIMESTAMP"

  # System-level configs (safe copy, ignore permissions)
  sudo rsync -a --no-perms --no-owner --no-group /etc/coolercontrol/ \
    "$BACKUP_DIR/$TIMESTAMP/etc-coolercontrol/" 2>/dev/null || true

  # User-level configs
  cp -r ~/.config/CoolerControl "$BACKUP_DIR/$TIMESTAMP/user-config" 2>/dev/null || true

  # CoolerControl state and profiles
  sudo rsync -a --no-perms --no-owner --no-group /var/lib/coolercontrol/ \
    "$BACKUP_DIR/$TIMESTAMP/var-lib-coolercontrol/" 2>/dev/null || true

  # 🧹 Remove restricted files (root-only) that can break git indexing
  find "$BACKUP_DIR/$TIMESTAMP" -type f -name ".passwd" -exec sudo rm -f {} \; 2>/dev/null || true

  # Optional: export profile from nct6799 (if supported)
  if command -v coolercontrol-cli &>/dev/null; then
    echo "📦 Exporting CoolerControl profiles..."
    coolercontrol-cli export --device nct6799 \
      --output "$BACKUP_DIR/$TIMESTAMP/nct6799-profile.json" 2>/dev/null || true
  fi

  # Sync as latest restore snapshot
  rm -rf "$RESTORE_DIR"
  cp -r "$BACKUP_DIR/$TIMESTAMP" "$RESTORE_DIR"

  echo "✅ Backup complete!"
  echo "📁 Saved in: $BACKUP_DIR/$TIMESTAMP"
}

restore_configs() {
  echo "🧊 Restoring CoolerControl configuration..."
  if [ ! -d "$RESTORE_DIR" ]; then
    echo "❌ No restore folder found in $RESTORE_DIR"
    exit 1
  fi

  sudo systemctl stop coolercontrold || true

  # Clear existing configs
  sudo rm -rf /etc/coolercontrol ~/.config/CoolerControl /var/lib/coolercontrol

  # Restore backups
  sudo rsync -a "$RESTORE_DIR/etc-coolercontrol/" /etc/coolercontrol/ 2>/dev/null || true
  rsync -a "$RESTORE_DIR/user-config/" ~/.config/CoolerControl/ 2>/dev/null || true
  sudo rsync -a "$RESTORE_DIR/var-lib-coolercontrol/" /var/lib/coolercontrol/ 2>/dev/null || true

  # Restore exported fan profile (if available)
  if [ -f "$RESTORE_DIR/nct6799-profile.json" ]; then
    echo "📥 Importing NCT6799 fan profile..."
    coolercontrol-cli import --input "$RESTORE_DIR/nct6799-profile.json" 2>/dev/null || true
  fi

  sudo systemctl restart coolercontrold
  echo "✅ CoolerControl restoration complete!"
}

case "$1" in
  backup)
    backup_configs
    ;;
  restore)
    restore_configs
    ;;
  *)
    echo "Usage: $0 {backup|restore}"
    exit 1
    ;;
esac

