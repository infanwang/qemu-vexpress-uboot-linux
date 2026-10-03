
常见问题 FAQ
编译
Q: undefined reference to __stack_chk_fail
A: 加 -fno-stack-protector

Q: undefined reference to xxx（inline 函数）
A: 加 -fgnu89-inline

Q: config.mk 追加 CFLAGS 没生效
A: 追加位置被后面覆盖。放在 config.mk 末尾。

QEMU
Q: -tftp: invalid option
A: QEMU 3.1 后移除。用 -net user,tftp=...

Q: -device lan9118: Parameter 'driver' expects a pluggable device type
A: lan9118 不是 qdev 设备。用 -net nic,model=lan9118

Q: TFTP error: 'Access violation' (2)
A: TFTP 根目录不存在或文件权限不对

Q: Wrong image format for "source" command
A: scriptaddr 与 fileaddr 不一致。setenv scriptaddr 0x60100000

内核
Q: Starting kernel ... 后无输出
A: 检查内核配置：

text
CONFIG_SERIAL_AMBA_PL011=y
CONFIG_SERIAL_AMBA_PL011_CONSOLE=y
Q: Kernel panic: VFS: Unable to mount root fs
A: rootfs 未挂载。检查：

-drive file=rootfs.ext4,if=sd 参数

root=/dev/mmcblk0 内核参数

rootfs 是否是有效 ext4 镜像

Q: /bin/sh: can't access tty
A: 无害警告。修法见 configs/rootfs-fix-rcS.sh

网络
Q: DHCP 拿不到 IP
A: 检查 QEMU -net user 配置，确认客户机网卡驱动（smc911x）已加载

Q: TFTP 传输速度慢
A: QEMU 用户模式网络本身较慢，正常
