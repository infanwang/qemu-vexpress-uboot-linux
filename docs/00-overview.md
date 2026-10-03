# 里程碑总览

## 起点
- 平台：Ubuntu 26.04 + GCC 14
- 目标：QEMU 里跑通 mini2440 的 U-Boot + Linux
- 难度：跨三代工具链（2009 U-Boot / 2011 QEMU fork / 2026 编译器）

## 最终交付

| 产物 | 大小 | 说明 |
|---|---|---|
| `u-boot-mini2440.bin` | 227KB | mini2440 U-Boot 1.3.2 |
| `u-boot-vexpress-a9.elf` | 5.2MB | 主线 U-Boot 2026.10（带符号） |
| `u-boot-vexpress-a9.bin` | 606KB | 主线 U-Boot（裸二进制） |
| `zImage` | 5.9MB | Linux 6.12.27 |
| `vexpress-v2p-ca9.dtb` | 14KB | 设备树 |
| `rootfs.ext4` | 64MB | Buildroot ext4 |
| `boot.scr.uimg` | 291B | U-Boot 自动启动脚本 |

## 完整链路
GCC 14 编译 U-Boot
↓
QEMU vexpress-a9 启动
↓
U-Boot 命令行
↓
TFTP 加载 zImage + dtb
↓
bootz 引导
↓
Linux 内核完整启动
↓
mount ext4 rootfs
↓
Run /sbin/init
↓
~ # (BusyBox shell)

text

## 关键数字

- **17 年**：GCC 4.x → GCC 14 时间跨度
- **8 类**：GCC 14 编译老 U-Boot 的问题
- **3 层**：QEMU mini2440 fork 修复的 bug
- **5 轮**：基于 gdb 假值的失败补丁
- **1 次**：方案切换（mini2440 → vexpress）
- **30 分钟**：vexpress 从零到 shell 的实际时间
