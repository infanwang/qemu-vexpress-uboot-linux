#!/bin/bash
# 生成 boot.scr.uimg
set -e

TFTP_DIR="${1:-$HOME/manual-build/tftp_root}"
MKIMAGE="${2:-$HOME/manual-build/uboot-mainline/tools/mkimage}"

mkdir -p "$TFTP_DIR"

cat > "$TFTP_DIR/boot.cmd" << 'CMDEOF'
setenv ipaddr 10.0.2.15
setenv serverip 10.0.2.2
setenv bootargs 'console=ttyAMA0,38400n8 root=/dev/mmcblk0 rw rootwait'
tftpboot 0x60100000 zImage
tftpboot 0x61000000 vexpress-v2p-ca9.dtb
bootz 0x60100000 - 0x61000000
CMDEOF

"$MKIMAGE" -A arm -T script -C none -n "vexpress boot" \
    -d "$TFTP_DIR/boot.cmd" "$TFTP_DIR/boot.scr.uimg"

ls -lh "$TFTP_DIR/boot.cmd" "$TFTP_DIR/boot.scr.uimg"
