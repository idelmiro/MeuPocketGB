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

# 5) Power-on screen: u-boot shows boot/miyoo-splash.bmp (Miyoo logo + version)
#    while the kernel loads. Replace it with our boot screen: the console name
#    in ASCII art + an empty progress bar, drawn with the kernel's 8x8 font so
#    it matches what /etc/main shows next (boot/gerar-tela-boot.py makes it).
#    u-boot's CFB only draws 4/8/24-bit BMPs: tela-boot.bmp is 8-bit 320x240.
cp "$HERE/boot/tela-boot.bmp" board/miyoo/meupocketgb-splash.bmp
GENIMG=board/miyoo/scripts/genimage.sh
if grep -q '^convert board/miyoo/miyoo-splash.png' "$GENIMG"; then
	sed -i 's|^convert board/miyoo/miyoo-splash.png .*BMP3:"${BINARIES_DIR}"/boot/miyoo-splash.bmp$|cp board/miyoo/meupocketgb-splash.bmp "${BINARIES_DIR}"/boot/miyoo-splash.bmp|' "$GENIMG"
fi
grep -q '^cp board/miyoo/meupocketgb-splash.bmp' "$GENIMG" || { echo "genimage.sh: logo do boot nao foi trocado" >&2; exit 1; }

# 6) ROMS ext4 with 4 KiB blocks. The image is small (136M), so mkfs picks
#    the "small" profile (1 KiB blocks); after firstboot grows it to the
#    whole card that means thousands of block groups and a slow mount
#    (~0.6 s on a 32 GB card). "-T default" keeps the normal 4 KiB layout.
sed -i 's|^mkfs.ext4 -d "${BINARIES_DIR}/roms/" -v |mkfs.ext4 -b 4096 -T default -d "${BINARIES_DIR}/roms/" -v |' "$GENIMG"
grep -q '^mkfs.ext4 -b 4096 -T default ' "$GENIMG" || { echo "genimage.sh: mkfs da ROMS nao foi ajustado" >&2; exit 1; }

# 7) MAIN (saves, settings) as ext4 instead of btrfs. Mounting btrfs makes the
#    kernel load btrfs + raid6 + xor (with a speed test) at every boot: ~0.5 s.
#    firstboot still offers BTRFS as the alternative and fixes inittab itself.
sed -i 's|^mkfs.btrfs -r "${BINARIES_DIR}/main/" -b ${MAIN_SIZE} .*$|dd if=/dev/zero of=${image} bs=${MAIN_SIZE} count=1 \&\& mkfs.ext4 -b 4096 -T default -d "${BINARIES_DIR}/main/" -v -L ${label} ${image}|' "$GENIMG"
grep -q '^dd if=/dev/zero of=${image} bs=${MAIN_SIZE} count=1 && mkfs.ext4 ' "$GENIMG" || { echo "genimage.sh: MAIN ainda em btrfs" >&2; exit 1; }
INITTAB=board/miyoo/rootfs/etc/inittab
sed -i -e 's|^::sysinit:/sbin/modprobe btrfs$|#&|' \
       -e 's|^\(::sysinit:/bin/mount /dev/mmcblk0p4 /mnt\) -o .*$|\1 -o rw,noatime,exec|' "$INITTAB"
grep -q '^#::sysinit:/sbin/modprobe btrfs$' "$INITTAB" && grep -q '^::sysinit:/bin/mount /dev/mmcblk0p4 /mnt -o rw,noatime,exec$' "$INITTAB" \
	|| { echo "inittab: MAIN ainda montada como btrfs" >&2; exit 1; }

# 8) First boot without the MiyooCFW installer: this image is only for the
#    PocketGo, so there are no questions (device, video tests, license,
#    filesystems). boot/firstboot sets the PocketGo, the swap and grows ROMS
#    to the whole card, silently, with the boot screen up.
install -m 0755 "$HERE/boot/firstboot" board/miyoo/boot/firstboot
grep -q '^# MeuPocketGB first boot' board/miyoo/boot/firstboot || { echo "firstboot do MeuPocketGB nao copiado" >&2; exit 1; }

echo "buildroot preparado para o MeuPocketGB"
