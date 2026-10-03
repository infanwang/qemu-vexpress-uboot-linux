# GCC 14 编译 2009 老 U-Boot 全记录

## 8 个坑

| # | 症状 | 根因 | 修法 |
|---|---|---|---|
| 1 | `undefined reference to __stack_chk_*` | GCC 默认开栈保护 | `-fno-stack-protector` |
| 2 | `undefined reference to wait_ms` | C99 inline 不生成外部符号 | `-fgnu89-inline` |
| 3 | `__inline__` 不产生外部符号 | C23 语义变化 | 删 `__inline__` |
| 4 | `inline` 引用 `.c` 里 static | C99 语义 | 把 static 改 extern |
| 5 | `cramfs_memset` undefined | 跨模块 inline 静态 | 去掉 `inline` |
| 6 | `config.mk` 追加没生效 | 追加位置被覆盖 | 放 `config.mk` 末尾 |
| 7 | `redefinition of wait_ms` | 重复补桩 | 删多余的 |
| 8 | `multiple definition of show_boot_progress` | 已有定义 | 删桩 |

## 通用编译配置

```makefile
# config.mk 追加
CFLAGS     += -fgnu89-inline -fno-stack-protector
AFLAGS     += -fno-stack-protector
HOSTCFLAGS += -fgnu89-inline
源码级修复（老 U-Boot 通用）
bash
# 去 __inline__
sed -i 's/void __inline__ wait_ms/void wait_ms/' include/usb.h common/usb.c

# 把 static 改 extern
sed -i 's/^static void __image_print_contents/void __image_print_contents/' common/image.c

# 去 inline
sed -i 's/^inline void cramfs_memset/void cramfs_memset/' fs/jffs2/mini_inflate.c
关键教训
遇到 undefined reference，第一件事是 grep -rn "符号名" --include=*.c .
找全部定义，看为什么没导出（static / inline / 条件编译）。
