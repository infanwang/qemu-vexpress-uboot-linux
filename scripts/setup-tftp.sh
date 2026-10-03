#!/bin/bash
# 准备 TFTP 目录
set -e

TFTP_DIR="${1:-$HOME/manual-build/tftp_root}"
mkdir -p "$TFTP_DIR"

echo "TFTP 目录：$TFTP_DIR"
echo ""
echo "需要放入以下文件："
echo "  - zImage                  （Linux 内核）"
echo "  - vexpress-v2p-ca9.dtb    （设备树）"
echo "  - boot.scr.uimg           （自动启动脚本）"
echo ""

if [ -f "$TFTP_DIR/boot.cmd" ]; then
    MKIMAGE="$(which mkimage 2>/dev/null || echo $HOME/manual-build/uboot-mainline/tools/mkimage)"
    [ -x "$MKIMAGE" ] && "$MKIMAGE" -A arm -T script -C none -n "vexpress boot" \
        -d "$TFTP_DIR/boot.cmd" "$TFTP_DIR/boot.scr.uimg"
    echo "已生成 boot.scr.uimg"
fi

ls -lh "$TFTP_DIR/" 2>/dev/null
