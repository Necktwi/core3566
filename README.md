# core3566

## gentoo installation
1. Follow https://wiki.luckfox.com/Core3566/Core3566-SDK up to 6th point.
```
cd ~/core3566/; mv kernel kernel-4.19.232; ln -s kernel-4.19.232 kernel; git init
git add remote origin https://gitlab.com/necktwiozfuagh/core3566.git
git pull
# Now download latest arm64 gentoo stage-3 as shown in the next point to gentoo folder.
cd gentoo;wget https://distfiles.gentoo.org/releases/arm64/autobuilds/20240317T232028Z/stage3-arm64-openrc-20240317T232028Z.tar.xz; cd ..
./build.sh lunch
# select BoardConfig-core3566_hdmi-gentoo-v1.mk
# you can place your configuration files in ./gentoo/myroot which will be copied to / in image that will be generated. Copy a gentoo's make.conf corresponding to the downloaded stage-3 to ./gentoo/myroot/etc/portage/make.conf and add VIDEO_CARDS="panfrost" to it
export RK_ROOTFS_SYSTEM=gentoo; ./build.sh
# ./rockdev/update.img will be generated which can be flashed to Core3566
```
2. once the Core3566 is booted expand the root partition using
- `sudo resize2fs /dev/mmcblk0p6`

## to build and install only kernel
1. start the vboxvm
```
export RK_ROOTFS_SYSTEM=gentoo
cd ~/core3566/kernel
make menuconfig #select the modules you need
cp .config core3566/kernel-4.19.232/arch/arm64/configs/luckfox_core3566_linux_defconfig
./build.sh kernel
./build.sh modules
```
2. copy `~/core3566/rockdev/[boot.img, parameter.txt]` to Windows host machine
3. start `rkdevtool.exe` and connect core3566
4. Add Item, set name boot, address as per parameter.txt(the hex number next to @), path to boot.img and Run.

### to generate full image without rebuilding everything
```
NOCLEAN=1 ./build.sh updateimg
```

Please rise an issue up on an query.
