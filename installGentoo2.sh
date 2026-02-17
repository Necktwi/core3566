#!/bin/bash
. /workspace/installGentoo-1.sh

. /etc/profile
if ! [ -d ~/workspace ]; then
	ln -s /workspace ~/
fi
cd ~/workspace
if [ ! -d rkbin ]; then
	echoH "Making rk356x spl loader..."
	git clone --depth=1 --recurse-submodules https://github.com/rockchip-linux/rkbin.git
	pushd rkbin
	./tools/boot_merger ./RKBOOT/RK3566MINIALL.ini
	popd
fi

if [ ! -d u-boot ]; then
	echoH "Cloning u-boot..."
	git clone --depth=1 --recurse-submodules -b v2026.01-core3566 https://github.com/Necktwi/u-boot.git
fi

echoH "Building u-boot..."
cd u-boot
make LLVM=1 LLVM_IAS=1 ARCH=arm SUBARCH=arm64 HOSTCC=clang CC=${TGTTPL}-clang AS=${TGTTPL}-clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf ELFEDIT=llvm-elfedit CROSS_COMPILE=${TGTTPL}- ROCKCHIP_TPL=../rkbin/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin BL31=../rkbin/bin/rk35/rk3568_bl31_v1.45.elf TEE=../rkbin/bin/rk35/rk3568_bl32_v2.15.bin core3566-rk3566_defconfig
make LLVM=1 LLVM_IAS=1 ARCH=arm SUBARCH=arm64 HOSTCC=clang CC=${TGTTPL}-clang AS=${TGTTPL}-clang LD=ld.lld AR=llvm-ar NM=llvm-nm OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump STRIP=llvm-strip READELF=llvm-readelf ELFEDIT=llvm-elfedit CROSS_COMPILE=${TGTTPL}- ROCKCHIP_TPL=../rkbin/bin/rk35/rk3566_ddr_1056MHz_v1.23.bin BL31=../rkbin/bin/rk35/rk3568_bl31_v1.45.elf TEE=../rkbin/bin/rk35/rk3568_bl32_v2.15.bin -j`nproc`

cd ~/workspace
if [ ! -d linux ]; then
	echoH "Cloning Linux..."
	git clone --depth=1 --recurse-submodules -b v6.18-core3566 https://github.com/Necktwi/linux.git
fi

echoH "Building Linux ..."
cd linux
make LLVM=1 LLVM_IAS=1 ARCH=arm64 HOSTCC=clang CC=${TGTTPL}-clang luckfox_core3566_linux_defconfig
make LLVM=1 LLVM_IAS=1 ARCH=arm64 HOSTCC=clang CC=${TGTTPL}-clang DTC_FLAGS="-@" Image rockchip/rk3566-core3566.dtb modules -j`nproc`

echoH "Installing modules..."
sudo make LLVM=1 LLVM_IAS=1 ARCH=arm64 HOSTCC=clang CC=${TGTTPL}-clang INSTALL_MOD_PATH=/usr/${TGTTPL}/ modules_install

echoH "Enabling prompt on serial port..."
sudo sed -i 's|f0:12345:respawn:/sbin/agetty 9600 ttyAMA0 vt100|s2:12345:respawn:/sbin/agetty -L ttyS2 1500000 vt100|' /usr/${TGTTPL}/etc/inittab

if ! grep PARTLABEL /usr/${TGTTPL}/etc/fstab; then
	echoH "Setting up kernel to mount partitions on root filesystem on boot..."
	sudo tee -a /usr/${TGTTPL}/etc/fstab <<EOF
PARTLABEL=boot		/boot		vfat		defaults	1 2
PARTLABEL=rootfs	/			ext4		defaults	0 1
EOF
fi

cd ~/workspace/
if [ ! -f extlinuxCore3566.conf ]; then
	echoH "Making extlinuxCore3566.conf for u-boot..."
	cat > extlinuxCore3566.conf <<EOF
LABEL Linux
KERNEL /Image
FDT /rk3566.dtb
APPEND root=PARTLABEL=rootfs rw rootwait earlycon=uart8250,mmio32,0xfe660000 console=ttyS2,1500000
EOF
fi

INIT_TIME=$(date +"%m%d%H%M%Y.%S")
echo "saved_time=${INIT_TIME}" | tee u-boot-time.env
tee boot.txt <<EOF
if load mmc 0:1 \${loadaddr} /u-boot-time.env; then
   env import -t \${loadaddr} \${filesize}
   date \${saved_time}
fi
# Continue with standard extlinux boot
sysboot mmc 0:1 fat \${loadaddr} /extlinux/extlinux.conf
EOF
./u-boot/tools/mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "Time Fix Script" -d boot.txt boot.scr
echoH "Baking bootfs..."
if ! [ -f bootCore3566.img ]; then
	truncate -s 64M bootCore3566.img
	mkfs.vfat bootCore3566.img
	mmd -i bootCore3566.img ::extlinux
fi
mcopy -i bootCore3566.img -o linux/arch/arm64/boot/dts/rockchip/rk3566-core3566.dtb ::rk3566.dtb
mcopy -i bootCore3566.img -o extlinuxCore3566.conf ::extlinux/extlinux.conf
mcopy -i bootCore3566.img -o linux/arch/arm64/boot/Image ::Image

echoH "Preparing first boot script..."
sudo tee /usr/${TGTTPL}/etc/local.d/firstBoot.start<<EOF
#!/bin/bash
CON="/dev/console"
sed -i '/^CBUILD=/d' /etc/portage/make.conf
sed -i 's/^ROOT=.*/ROOT="\/"/' /etc/portage/make.conf
echo "Expanding rootfs..."
resize2fs /dev/mmcblk1p2
rm /etc/local.d/firstBoot.start
EOF
sudo chmod +x /usr/${TGTTPL}/etc/local.d/firstBoot.start

echoH "Enabling software clock..."
pushd /usr/${TGTTPL}/etc/runlevels/boot/
if ! [ -f ./swclock ]; then
	sudo ln -s /etc/init.d/swclock ./
fi
sudo mkdir -p /usr/${TGTTPL}/var/lib/misc
sudo touch /usr/${TGTTPL}/var/lib/misc/openrc-shutdowntime

echoH "Enabling ssh server..."
if ! [ -f ./sshd ]; then
	sudo ln -s /etc/init.d/sshd ./
fi

echoH "Enabling system log ..."
if ! [ -f ./sysklogd ]; then
	sudo ln -s /etc/init.d/sysklogd ./
fi
popd

echoH "Making rootfs..."
if [ -f rootfsCore3566GentooMuslLlvm.img ]; then
   sudo rm rootfsCore3566GentooMuslLlvm.img
fi
sudo mke2fs -d /usr/${TGTTPL}/ -t ext4 rootfsCore3566GentooMuslLlvm.img 2G

if [ ! -f parameterCore3566.txt ]; then
	echoH "Planning disk layout..."
	tee parameterCore3566.txt <<EOF
FIRMWARE_VER: 1.0
MACHINE_MODEL: Core3566
MACHINE_ID: 007
MANUFACTURER: Luckfox
MAGIC: 0x5041524B
ATAG: 0x00200800
MACHINE: 0xffffffff
CHECK_MASK: 0x80
PWR_HLD: 0,0,A,0,1
TYPE: GPT
CMDLINE: mtdparts=rk29xxnand:0x00020000@0x00005000(boot),-@0x00025000(rootfs:grow)
EOF
fi

if [ ! -d rkdeveloptool ]; then
	echoH "Cloning n building rkdeveloptool..."
	git clone --depth=1 --recurse-submodules -b musl https://github.com/Necktwi/rkdeveloptool.git
	cd rkdeveloptool
	./autogen.sh
	./configure
	make -j`nproc`
else
	cd rkdeveloptool
fi

while ! lsusb|grep 2207:350; do
	echoH "Core3566 not found"
	read -p "connect in maskrom mode(turn on boot button of base board and hold boot button on Core3566 untill u connect)  and press Enter..."	
done
echoH "Core3566 found!"

echoH "Flash begins..."
sudo ./rkdeveloptool db ../rkbin/rk356x_spl_loader_v*.bin

echoH "Creating GPT layout on mmec..."
sudo ./rkdeveloptool gpt ../parameterCore3566.txt
sudo ./rkdeveloptool ppt

echoH "Flashing u-boot..."
sudo ./rkdeveloptool wl 0x40 ../u-boot/u-boot-rockchip.bin

echoH "Flashing bootfs..."
sudo ./rkdeveloptool wl 0x5000 ../bootCore3566.img

echoH "Flashing rootfs..."
sudo ./rkdeveloptool wl 0x25000 ../rootfsCore3566GentooMuslLlvm.img

echoH "Done! Rebooting..."
sudo ./rkdeveloptool rd

echoHB "Gentoo installed.\n"
