#!/bin/bash
# QEMU vexpress-a9：一键启动 U-Boot + TFTP + Linux
set -e

BASE_DIR="${BASE_DIR:-$HOME/manual-build}"
UBOOT_ELF="${UBOOT_ELF:-$BASE_DIR/outputs/u-boot-vexpress-a9.elf}"
TFTP_DIR="${TFTP_DIR:-$BASE_DIR/tftp_root}"
ROOTFS="${ROOTFS:-$BASE_DIR/rootfs.ext4}"

[ ! -f "$UBOOT_ELF" ] && { echo "错误：U-Boot ELF 不存在：$UBOOT_ELF" >&2; exit 1; }
[ ! -d "$TFTP_DIR"  ] && { echo "错误：TFTP 目录不存在：$TFTP_DIR"  >&2; exit 1; }

exec qemu-system-arm \
    -M vexpress-a9 \
    -m 256M \
    -nographic \
    -kernel "$UBOOT_ELF" \
    -net nic,model=lan9118 \
    -net user,tftp="$TFTP_DIR",bootfile=boot.scr.uimg \
    -drive file="$ROOTFS",if=sd,format=raw
