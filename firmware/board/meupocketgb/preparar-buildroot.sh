#!/bin/bash
# MeuPocketGB: adjusts a fresh MiyooCFW/buildroot checkout before building.
# Usage (from anywhere): preparar-buildroot.sh <buildroot dir>
#
# - options.cfg: no boot logo animation, no USB gadget (faster boot)
# - firstboot: drop the GMenu2X/RetroArch setup part (not installed here)
# - MAIN partition: keep only the hotkey/volume/brightness settings
# - ROMS partition: keep only the free homebrew GB/GBC sample games
set -euo pipefail

BR="${1:?informe a pasta do buildroot}"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$BR"

test -f board/miyoo/boot/firstboot || { echo "Nao parece ser o MiyooCFW/buildroot: $BR" >&2; exit 1; }

# 1) BOOT partition settings
cp "$HERE/boot/options.cfg" board/miyoo/boot/options.cfg

# 2) firstboot without GMenu2X/RetroArch: delete from "# GMenu2X setup" up to
#    the "retroarch-setup -d lock" line (kept: device detection + partitions)
if grep -q '^# GMenu2X setup' board/miyoo/boot/firstboot; then
	sed -i '/^# GMenu2X setup/,/^retroarch-setup -d lock/d' board/miyoo/boot/firstboot
fi
grep -q 'retroarch-setup' board/miyoo/boot/firstboot && { echo "firstboot: trecho do GMenu2X nao removido" >&2; exit 1; }

# 3) MAIN partition content
find board/miyoo/main -mindepth 1 -maxdepth 1 \
	! -name '.backlight.conf' ! -name '.batterylow.conf' ! -name '.buttons.conf' \
	! -name '.volume.conf' ! -name 'autorun.inf' ! -name 'main.ico' \
	-exec rm -rf {} +

# 4) ROMS partition content (homebrew samples; copy your own ROMs later)
rm -rf board/miyoo/roms/NES board/miyoo/roms/GBA
cp "$HERE/roms/LEIA-ME.txt" board/miyoo/roms/LEIA-ME.txt

echo "buildroot preparado para o MeuPocketGB"
