# core3566

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

Please rise an issue up on an issue.
