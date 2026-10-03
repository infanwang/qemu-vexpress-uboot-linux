
vexpress-a9 完整链路：从零到 Linux Shell
步骤 1：编译主线 U-Boot
bash
git clone --depth 1 https://github.com/u-boot/u-boot.git uboot-mainline
cd uboot-mainline
export CROSS_COMPILE=arm-buildroot-linux-gnueabihf-
export ARCH=arm
make vexpress_ca9x4_defconfig
make -j$(nproc)
# 产物：u-boot (5.2M ELF) + u-boot.bin (606K)
步骤 2：准备 TFTP 目录
bash
mkdir -p ~/manual-build/tftp_root
cp /path/to/zImage                ~/manual-build/tftp_root/
cp /path/to/vexpress-v2p-ca9.dtb  ~/manual-build/tftp_root/
步骤 3：写 U-Boot 自动启动脚本
bash
cat > ~/manual-build/tftp_root/boot.cmd << 'EOF'
setenv ipaddr 10.0.2.15
setenv serverip 10.0.2.2
setenv bootargs 'console=ttyAMA0,38400n8 root=/dev/mmcblk0 rw rootwait'
tftpboot 0x60100000 zImage
tftpboot 0x61000000 vexpress-v2p-ca9.dtb
bootz 0x60100000 - 0x61000000
EOF

~/manual-build/uboot-mainline/tools/mkimage \
    -A arm -T script -C none -n "vexpress boot" \
    -d boot.cmd boot.scr.uimg
步骤 4：启动 QEMU
bash
qemu-system-arm \
    -M vexpress-a9 \
    -m 256M \
    -nographic \
    -kernel u-boot \
    -net nic,model=lan9118 \
    -net user,tftp=$HOME/manual-build/tftp_root,bootfile=boot.scr.uimg \
    -drive file=$HOME/manual-build/rootfs.ext4,if=sd,format=raw
步骤 5：观察完整链路
text
U-Boot 2026.10-rc5 ...
DRAM:  256 MiB
...
DHCP client bound to address 10.0.2.15
Filename 'boot.scr.uimg'.
Bytes transferred = 291
## Executing script at 60100000
Filename 'zImage'.
Bytes transferred = 5897952
Filename 'vexpress-v2p-ca9.dtb'.
Bytes transferred = 14329
Starting kernel ...
[    0.000000] Booting Linux on physical CPU 0x0
...
VFS: Mounted root (ext4 filesystem) on device 179:0.
Run /sbin/init as init process
Welcome to Vexpress Linux!
~ #                       ← ★ 目标达成
关键坑点
坑 1：-tftp 选项被移除
QEMU 3.1 后移除 -tftp /path。用 -net user,tftp=/path。

坑 2：-device lan9118 不支持
lan9118 不是 qdev 设备，用 -net nic,model=lan9118。

坑 3：scriptaddr 与 fileaddr 不一致
dhcp ${scriptaddr} ${boot_script_dhcp} 下载到 fileaddr（DHCP 给的 0x60100000），
但 source ${scriptaddr} 用 scriptaddr（默认 0x90000000）——不一致 → 失败。

修法：

bash
setenv scriptaddr 0x60100000
setenv pxefile_addr_r 0x60200000
