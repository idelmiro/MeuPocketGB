#!/bin/bash
# MeuPocketGB: builds the full SD card image (.img) for the PocketGo.
#
# Needs a Debian/Ubuntu PC (or the GitHub Actions workflow), ~15 GB free and
# a few hours the first time. Result: buildroot/output/images/meupocketgb-*.img
#
# Usage: scripts/build-firmware.sh [pasta_de_trabalho]
#        SO_CONFIG=1 scripts/build-firmware.sh   (only prepares and checks the config)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${1:-$REPO/build}"
EXT="$REPO/firmware"
# MiyooCFW/buildroot, fixed commit (update on purpose, then test)
BR_URL="https://github.com/MiyooCFW/buildroot.git"
BR_COMMIT="d5912eeb7b636810bafaa34eb0517fd599a0fc71"
BR="$WORK/buildroot"

mkdir -p "$WORK"
if ! test -d "$BR/.git"; then
	git init -q "$BR"
	git -C "$BR" remote add origin "$BR_URL"
fi
git -C "$BR" fetch -q --depth 1 origin "$BR_COMMIT"
git -C "$BR" checkout -qf FETCH_HEAD
git -C "$BR" clean -fdq -e output -e dl
git -C "$BR" config user.email "meupocketgb@localhost"
git -C "$BR" config user.name "MeuPocketGB"

"$EXT/board/meupocketgb/preparar-buildroot.sh" "$BR"
# commit the adjustments so the upstream image script doesn't mark it "dirty"
git -C "$BR" add -A board/miyoo
git -C "$BR" commit -qm "MeuPocketGB: ajustes do preparar-buildroot.sh" || true

cd "$BR"
make BR2_EXTERNAL="$EXT" miyoo_uclibc_defconfig
support/kconfig/merge_config.sh -m .config \
	board/miyoo/minconfig/rootfs-size-fragment.config \
	board/miyoo/minconfig/min-pkgs-fragment.config \
	"$EXT/configs/meupocketgb.fragment"
make BR2_EXTERNAL="$EXT" olddefconfig

# check that the important choices survived kconfig
for opt in BR2_PACKAGE_GAMBATTE_MEUPOCKETGB=y; do
	grep -qx "$opt" .config || { echo "ERRO: $opt nao ficou no .config" >&2; exit 1; }
done
for opt in BR2_PACKAGE_GMENU2X BR2_PACKAGE_RETROARCH BR2_PACKAGE_IPK_GAMBATTE; do
	if grep -qx "$opt=y" .config; then echo "ERRO: $opt ainda ativo" >&2; exit 1; fi
done

if test "${SO_CONFIG:-0}" = 1; then
	echo "SO_CONFIG=1: configuracao pronta em $BR/.config (nada foi compilado)"
	exit 0
fi

make -j"$(getconf _NPROCESSORS_ONLN)" MINIMAL="yes"

cd output/images
for img in miyoo-*.img; do
	mv "$img" "meupocketgb-${img#miyoo-}"
done
ls -lh meupocketgb-*.img
