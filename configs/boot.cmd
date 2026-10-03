setenv ipaddr 10.0.2.15
setenv serverip 10.0.2.2
setenv bootargs 'console=ttyAMA0,38400n8 root=/dev/mmcblk0 rw rootwait'
tftpboot 0x60100000 zImage
tftpboot 0x61000000 vexpress-v2p-ca9.dtb
bootz 0x60100000 - 0x61000000
