#!/bin/bash
# 修复 rootfs 的 /dev/tty 节点和 rcS
# 用法：sudo ./rootfs-fix-rcS.sh [rootfs.ext4] [挂载点]
set -e

ROOTFS="${1:-$HOME/manual-build/rootfs.ext4}"
MNT="${2:-/mnt/rootfs_fix}"

[ ! -f "$ROOTFS" ] && { echo "错误：rootfs 不存在：$ROOTFS" >&2; exit 1; }

sudo mkdir -p "$MNT"
sudo mount "$ROOTFS" "$MNT"

# ── 创建 tty 设备节点 ──
for i in 0 1 2 3 4 5 6; do
    sudo mknod -m 620 "$MNT/dev/tty$i" c 4 $i 2>/dev/null || true
done
sudo mknod -m 600 "$MNT/dev/console" c 5 1 2>/dev/null || true
sudo mknod -m 666 "$MNT/dev/null"    c 1 3 2>/dev/null || true

# ── 写一个简单的 rcS ──
sudo mkdir -p "$MNT/etc/init.d"
sudo tee "$MNT/etc/init.d/rcS" > /dev/null << 'RCEOF'
#!/bin/sh
mount -t proc   none /proc
mount -t sysfs  none /sys
mount -t devtmpfs none /dev 2>/dev/null || true
echo
echo "========================================"
echo "  Welcome to Vexpress-A9 Linux"
echo "  U-Boot → TFTP → Kernel → ext4 rootfs"
echo "========================================"
echo
exec /bin/sh
RCEOF
sudo chmod +x "$MNT/etc/init.d/rcS"

sudo umount "$MNT"
echo "✅ rootfs 修复完成：$ROOTFS"
