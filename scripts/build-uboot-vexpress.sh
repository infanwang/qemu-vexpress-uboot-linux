#!/bin/bash
# 从零编译主线 U-Boot（vexpress-a9）
set -e

GIT_URL="https://github.com/u-boot/u-boot.git"
WORK_DIR="${WORK_DIR:-$HOME/manual-build/uboot-mainline}"
CROSS_COMPILE="${CROSS_COMPILE:-arm-buildroot-linux-gnueabihf-}"

[ ! -d "$WORK_DIR" ] && git clone --depth 1 "$GIT_URL" "$WORK_DIR"
cd "$WORK_DIR"
export CROSS_COMPILE ARCH=arm

make vexpress_ca9x4_defconfig
make -j$(nproc)

echo "产物："
ls -lh u-boot u-boot.bin
