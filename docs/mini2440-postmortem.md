# mini2440 路线复盘：为什么最终切换到 QEMU 主线

> 结论：mini2440（QEMU 0.10 fork + 2009 年代 U-Boot）在 Ubuntu 26.04 / GCC 14 环境下，**编译问题全部解决，但运行期崩溃的根因没有定位**。继续投入的边际收益低于切换到 QEMU 主线 `vexpress-a9`，因此止损切换。

## 1. 路线与结果

| 阶段 | 目标 | 结果 |
|---|---|---|
| QEMU 0.10 mini2440 fork 编译 | 在 GCC 14 上编出 `qemu-system-arm` | ✅ 7 类编译错误逐个修复后成功 |
| U-Boot (2009) 编译 | 编出 `u-boot.bin` | ✅ 约 227 KB，host 侧 `mkimage` 链接问题已解决 |
| QEMU 运行 U-Boot | 出现 `=>` 提示符 | ❌ 运行期崩溃，根因未定位 |
| 切换 | QEMU 主线 + vexpress + 新版 U-Boot | ✅ 见仓库主文档 |

## 2. 编译阶段：GCC 14 兼容修复清单

### QEMU 0.10

| # | 现象 | 原因 | 修复 |
|---|---|---|---|
| 1 | `QEMU requires SDL or Cocoa` | 缺 SDL | 安装 `libsdl1.2-dev` |
| 2 | `unknown option --disable-gtk` | 旧版无此选项 | 去掉该参数 |
| 3 | `gnutls_kx_set_priority` 未声明 | gnutls API 已废弃 | `--disable-vnc-tls --disable-vnc-sasl` |
| 4 | `typedef bool` 报错 | GCC 14 默认 C23，`bool` 为关键字 | `--extra-cflags="-std=gnu99"` |
| 5 | `hw/eepro100.c`、`dis-asm.h` 同类错误 | 同上 | 改为 `#include <stdbool.h>` |
| 6 | `container_of` 指针类型不兼容 | 宏内 `const` 与新编译器检查冲突 | 去掉 `const`，加 `-Wno-incompatible-pointer-types` |
| 7 | 大量 warning | 老代码 vs 新编译器 | `-w`、`-fcommon`、`-Wno-int-conversion` |

### U-Boot (2009)

| 现象 | 原因 | 修复 |
|---|---|---|
| host 侧 `mkimage` 链接报 `undefined reference to image_print_contents_noindent` | 老代码依赖 **GNU89 inline 语义**（普通 `inline` 同时生成外部符号）；GCC 5+ 默认 gnu11/gnu17，走 C99 语义，不生成外部符号 | `tools/Makefile` 追加 `-fgnu89-inline` |
| 目标侧同类风险 | 交叉编译器同样默认 gnu17 | 目标侧也加 `-fgnu89-inline`；用 `nm common/image.o` 确认符号为 `T` |

**经验**：看到 `inline function ... declared but never defined` 一类警告，就是 GNU89/C99 inline 语义冲突的前兆，应在链接失败之前处理。

## 3. 运行期崩溃：已知与未知

### 已确认并修复的真 bug（mini2440.c）

1. `nand_idx` 误用了 `nor_idx`
2. `BOOT_NOR` 赋值错误

### 未解决

- 崩溃地址稳定复现为客户机地址 `0x33F80068`（U-Boot 的 `TEXT_BASE=0x33F80000` 附近）。
- 崩溃时 gdb 寄存器快照里 `rbp = 0x33f80068`，而宿主栈指针应为 `0x7fff...`：**说明客户机地址被当成了宿主指针/栈值使用**。
- 这是确定性 bug，说明问题出在地址转换链上，但具体哪一层出错没有拿到证据。
- 待验证的假设（均未证实，仅作后续线索）：旧版 `exec.c` / RAM 注册路径对 **RAM 基址 ≠ 0**（mini2440 的 SDRAM 在 `0x30000000`）在 64 位宿主上的处理有问题；`ram_addr` 与客户机 PA 语义混用。

### 走过的弯路（5 轮无效补丁）

| 轮次 | 假设 | 补丁位置 | 结果 |
|---|---|---|---|
| 3 | `phys_pc` 未归一化 | `tb_alloc_page` | ❌ |
| 4 | 同上 | `tb_link_phys` | ❌ |
| 5 | 同上 | `tb_gen_code` + `asm` 屏障 | ❌ |
| 6 | 同上 | `tlb_protect_code` + `noinline` | ❌ |
| 7 | `phys_page2` 未归一化 | `tb_gen_code` | ❌（`phys_page2 = -1` 本就正确，表示无第二页） |

问题在于：5 轮补丁都建立在 gdb 显示的 `phys_pc` 值上，而该值在 `-O2` 下是失真的寄存器残留；失败后又归因为"编译器优化掉了补丁"，没有回头检验前提。

## 4. 方法论教训

1. **先打印，后假设**。沿调用链一次性打印同一个关键值：
   ```c
   #define DBG_TAG(tag, ...) fprintf(stderr, "[%s] " __VA_ARGS__, tag)
   // get_phys_addr_code / tb_gen_code / tb_link_phys / tb_alloc_page / tlb_protect_code
   ```
   一次运行就能看出"第一个出错的值在哪一层"。
2. **`-O2` 下 gdb 的变量值不可信**。可信度从高到低：`objdump -d` 反汇编 > `fprintf` 输出 > 寄存器/内存 dump > gdb 变量名显示。
3. **不要先怀疑编译器**。只有当独立手段（`fprintf`/`objdump`）证实差异时才怀疑优化；`asm volatile`、`volatile`、`noinline` 三件套在前提未证实时没有意义。
4. **第一次补丁失败就停**。回到"分层定位"，换一层，而不是在同一假设上换位置再试。
5. **每个地址变量标注语义**（VA / PA / `ram_addr` / HVA），避免混用：

   | 名称 | 含义 | 例 |
   |---|---|---|
   | VA | 客户机虚拟地址 | `0x33F80000` |
   | PA | 客户机物理地址 | `0x33F80000` |
   | `ram_addr` | RAM 偏移 | `0x03F80000` |
   | HVA | 宿主虚拟地址 | `0x7ffff4ea5010` |
6. **补丁生效要用独立证据确认**：clean rebuild 后，在补丁处再加一行 `fprintf`。

## 5. 止损判断标准

当满足以下任一条时应停止在老工具链上继续修复：

- 修复不再增加对**实验目标**（U-Boot 启动流程、NAND/NOR、内核引导）的理解，只是在和工具链较劲；
- 同一层连续两次补丁失败，且没有独立证据支持当前假设；
- 存在维护中的等价替代方案（此处为 QEMU 主线 `vexpress-a9` + 新版 U-Boot）。

## 6. 如果以后想回头

- 优先使用**旧环境**而不是在 GCC 14 上硬修：Ubuntu 18.04 容器 + GCC 7，QEMU 0.10 的 64 位宿主兼容问题会少很多。
- 或者在 32 位宿主 / `-m32` 构建下验证"RAM 基址 ≠ 0 + 64 位宿主"的假设。
- 入手点：先把上面的 `DBG_TAG` 调用链打印跑通，再动代码。

## 7. 本次保留的资产

- GCC 14 编译老代码的修复清单（第 2 节）
- QEMU 内部地址链调试方法（第 4 节）
- 已修复的两处真 bug：`nand_idx`、`BOOT_NOR`

