# QEMU vexpress-a9 + U-Boot + Linux 完整构建归档

> 在 Ubuntu 26.04 + GCC 14 上，从零构建可复现的嵌入式 Linux 引导链：
> **U-Boot 2026.10** → **TFTP 网络引导** → **Linux 6.12.27** → **ext4 rootfs** → **BusyBox shell**

## 🎯 项目背景

1. **起点**：在 Ubuntu 26.04 + GCC 14 上编译 2009 年的 U-Boot 1.3.2（mini2440）
2. **过程**：跨 17 年工具链兼容性，深入 QEMU mini2440 fork 的 5 层 bug
3. **转折**：mini2440 QEMU fork 存在无法修复的 TCG 架构问题 → 切换到主线 vexpress-a9
4. **成功**：完整走通"U-Boot → TFTP → Linux → rootfs → shell"链路

## 🏁 里程碑

| 里程碑 | 状态 |
|---|---|
| GCC 14 编译老 U-Boot 1.3.2 | ✅ |
| mini2440 U-Boot 编译（227KB） | ✅ |
| QEMU mini2440 fork 调试 | ⏸ TCG 架构 bug |
| 主线 U-Boot 2026.10 编译 | ✅ |
| QEMU vexpress-a9 启动 U-Boot | ✅ |
| TFTP 加载内核 + dtb | ✅ |
| `bootz` 引导 Linux 6.12.27 | ✅ |
| 挂载 ext4 rootfs | ✅ |
| **进入 BusyBox shell（`~ #`）** | ✅ |

## 📁 目录结构
￼
￼
.
├── README.md
├── docs/ # 6 篇文档（见 docs/00-overview.md）
├── scripts/ # 4 个一键脚本
├── configs/ # U-Boot 启动脚本 + rootfs 修复
├── artifacts/ # U-Boot ELF/BIN + dtb + SHA256SUMS
└── releases/ # 大产物说明（zImage / rootfs.ext4）
text
￼
￼
复制
￼
￼
下载
## 🚀 快速开始

```bash
# 前置依赖
sudo apt install -y build-essential git qemu-system-arm \
                    gcc-arm-linux-gnueabihf device-tree-compiler u-boot-tools

# 一键启动
./scripts/setup-tftp.sh              # 准备 TFTP 目录
./scripts/run-vexpress-a9.sh         # 启动 QEMU
￼
￼
📚 文档索引
￼
￼
文档
内容
docs/00-overview.md
里程碑总览
docs/01-gcc14-uboot-build.md
GCC 14 编译踩坑（8 类问题）
docs/02-qemu-mini2440-debug.md
QEMU mini2440 fork 调试复盘
docs/03-vexpress-full-bringup.md
vexpress 完整链路
docs/04-lessons-learned.md
⭐ 方法论总结（最推荐）
docs/05-troubleshooting.md
FAQ
🎓 核心教训
1. 编译失败是兼容性问题；QEMU 崩溃是架构性问题——要判断"是否值得修"
2. 用 fprintf 打印真值；gdb 在 -O2 下显示的值会骗人
3. 分层定位，不要跨层打补丁——第 1 次失败就停下重新分析
4. 识别"死路"比"坚持"更重要
详见 docs/04-lessons-learned.md。
📄 License
• 文档 + 脚本：MIT
• 引用自 U-Boot / Linux / QEMU 的代码：GPL-2.0
