
大产物说明
以下文件不进 git（体积大），需自行准备：

文件	大小	获取方式
zImage	5.9MB	用 Buildroot 编译，或从 ~/manual-build/artifacts/ 拷贝
rootfs.ext4	64MB	同上
从 Buildroot 构建
bash
make qemu_arm_vexpress_defconfig
make linux-rebuild all
# 产物在 output/images/
从现有环境拷贝
bash
cp ~/manual-build/artifacts/zImage                tftp_root/
cp ~/manual-build/artifacts/vexpress-v2p-ca9.dtb  tftp_root/
cp ~/manual-build/rootfs.ext4                     ./
编译内核
bash
cd /path/to/linux-6.12.27
make ARCH=arm CROSS_COMPILE=arm-buildroot-linux-gnueabihf- vexpress_defconfig
make ARCH=arm CROSS_COMPILE=arm-buildroot-linux-gnueabihf- -j$(nproc) zImage dtbs
