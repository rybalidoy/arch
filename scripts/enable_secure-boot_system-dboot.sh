#!/bin/bash

sbctl create-keys
sbctl enroll-keys --microsoft

sbctl verify
sbctl sign -s /boot/EFI/systemd/systemd-bootx64.efi
sbctl sign /boot/EFI/BOOT/BOOTx64.EFI
sudo sbctl sign /boot/vmlinuz-linux

sbctl sign-all
