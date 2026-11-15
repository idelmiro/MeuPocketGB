#!/bin/bash
# MeuPocketGB: builds the Gambatte binary for the "modo rapido" (card that
# already has MiyooCFW 2.0). The binary is static, so it runs on both the
# uClibc and the musl MiyooCFW images.
#
# Needs the MiyooCFW *static musl* SDK in /opt/miyoo (or SDK=/other/path).
# Without it, run with FAZER_SDK=1 to build the SDK first (takes hours).
#
# Usage: scripts/build-emulador.sh [pasta_de_trabalho]
# Result: <pasta_de_trabalho>/gambatte-meupocketgb
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${1:-$REPO/build}"
SDK="${SDK:-/opt/miyoo}"
GAMBATTE_URL="https://github.com/tiopex/gambatte-dms.git"
GAMBATTE_COMMIT="0b0416f70ad46a85c298c8d6f5d272f54cf267bc"
BR_URL="https://github.com/MiyooCFW/buildroot.git"
BR_COMMIT="d5912eeb7b636810bafaa34eb0517fd599a0fc71"

mkdir -p "$WORK"

if test "${FAZER_SDK:-0}" = 1; then
	BR="$WORK/buildroot-sdk"
	if ! test -d "$BR/.git"; then
		git init -q "$BR"
		git -C "$BR" remote add origin "$BR_URL"
	fi
	git -C "$BR" fetch -q --depth 1 origin "$BR_COMMIT"
	git -C "$BR" checkout -qf FETCH_HEAD
	(
		cd "$BR"
		make miyoo_musl_static_defconfig
		# the upstream "minimal" package list is enough for Gambatte
		support/kconfig/merge_config.sh -m .config board/miyoo/minconfig/min-pkgs-fragment.config
		make olddefconfig
		make -j"$(getconf _NPROCESSORS_ONLN)" sdk
	)
	SUDO=""
	if ! test -w "$(dirname "$SDK")" && ! test -w "$SDK"; then SUDO=sudo; fi
	$SUDO mkdir -p "$SDK"
	$SUDO find "$SDK" -mindepth 1 -delete
	$SUDO tar -xzf "$BR"/output/images/arm-miyoo-linux-musleabi_sdk-buildroot.tar.gz -C "$SDK" --strip-components=1
	$SUDO "$SDK/relocate-sdk.sh"
fi

CROSS="$SDK/bin/arm-miyoo-linux-musleabi-"
test -x "${CROSS}gcc" || { echo "SDK nao encontrado em $SDK (use FAZER_SDK=1)" >&2; exit 1; }

SRC="$WORK/gambatte-dms"
rm -rf "$SRC"
git init -q "$SRC"
git -C "$SRC" remote add origin "$GAMBATTE_URL"
git -C "$SRC" fetch -q --depth 1 origin "$GAMBATTE_COMMIT"
git -C "$SRC" checkout -qf FETCH_HEAD
for p in "$REPO"/emulador/patches/*.patch; do
	echo "aplicando $(basename "$p")"
	patch -d "$SRC" -p1 --no-backup-if-mismatch < "$p"
done

make -C "$SRC" -f Makefile.meupocketgb -j"$(getconf _NPROCESSORS_ONLN)" \
	CROSS_COMPILE="$CROSS" STATIC=1 OUTPUTNAME=gambatte-meupocketgb
cp "$SRC/gambatte-meupocketgb" "$WORK/gambatte-meupocketgb"
file "$WORK/gambatte-meupocketgb" || true
ls -l "$WORK/gambatte-meupocketgb"
