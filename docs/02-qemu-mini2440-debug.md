
QEMU mini2440 fork 调试复盘
三层 bug
第 1 层：mini2440.c 的 copy-paste bug（✅ 修复）
c
// 修复前
} else if (!strcasecmp(boot_mode, "nand")) {
    if (nor_idx < 0) {                // ← 用了 nor_idx（错）
        printf("nand error...");
        abort();
    } else
        mini->boot_mode = BOOT_NOR;   // ← 赋值 BOOT_NOR（错）
}

// 修复后
    if (nand_idx < 0) {
        printf("nand error, no NAND device specified");
        abort();
    } else
        mini->boot_mode = BOOT_NAND;
第 2 层：tlb_reset_dirty_range 崩溃（✅ 绕过）
临时 return; 禁用（不影响 U-Boot 启动）。

第 3 层：地址转换链条（✅ 完全正确）
fprintf 打印整条链：

text
[GPA] pc=0x33f80000 -> phys_pc=0x3f80000      ✅
[TAP] n=0 page_addr=0x3f80000                 ✅
[TPC] ram_addr=0x3f80000 last_ram_offset=0x4201000  ✅
所有地址都正确——5 轮补丁全部修错了地方。

第 4 层：TCG 污染宿主机栈（❌ 死路）
text
rbp = 0x33f80068       ← 宿主机栈帧指针变成客户机地址
r13 = 0x33f80000
#1  0x0000000033f80000 ← 返回地址是客户机地址
cpu_gen_code 把客户机地址写进宿主机栈——需要逐条反汇编 TCG 生成的代码，数天工作量。

5 轮失败的原因
轮次	判断的根因	补丁位置	结果
1	phys_pc 未归一化	tb_alloc_page	❌ GCC 消除
2	同上	tb_link_phys	❌ GCC 消除
3	同上	tb_gen_code + asm	❌ GCC 消除
4	同上	tlb_protect_code + noinline	❌ 地址本来就对
5	phys_page2 未归一化	tb_gen_code	❌ phys_page2=-1 是对的
核心错误：用 gdb 显示的 phys_pc=0x3F80000 推理，但那是 -O2 下的寄存器残留（假值）。

教训
gdb 显示的变量值在 -O2 下不可信 → 用 fprintf 打印

分层定位而非跨层补丁 → 沿调用链打印所有关键值

第 4 层是架构级死路 → 应该早识别并切换

最终决策
切到 主线 U-Boot + 主线 QEMU + vexpress-a9——30 分钟跑通。
