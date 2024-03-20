#!/bin/bash -ex

# Directory contains the target rootfs
TARGET_ROOTFS_DIR="binary"

case "${ARCH:-$1}" in
	arm|arm32|armhf)
		ARCH=armhf
		;;
	*)
		ARCH=arm64
		;;
esac

echo -e "\033[36m Building for $ARCH \033[0m"

if [ ! $VERSION ]; then
	VERSION="release"
fi

echo -e "\033[36m Building for $VERSION \033[0m"

if [ ! -e stage3-*.tar.xz ]; then
	echo -e "\033[36m download stage3-amd64-*.tar.xz first \033[0m"
	exit -1
fi

finish() {
   # sudo umount -R $TARGET_ROOTFS_DIR/dev
   # sudo umount -R $TARGET_ROOTFS_DIR/sys
   # sudo umount -R $TARGET_ROOTFS_DIR/proc
   # sudo umount -R $TARGET_ROOTFS_DIR/run
	exit -1
}
trap finish ERR

echo -e "\033[36m Extract image \033[0m"
sudo mkdir -p $TARGET_ROOTFS_DIR && cd $TARGET_ROOTFS_DIR
sudo tar -xvf ../stage3-*.tar.xz

# # packages folder
# sudo mkdir -p $TARGET_ROOTFS_DIR/packages
# sudo cp -rf packages/$ARCH/* $TARGET_ROOTFS_DIR/packages

# overlay folder
sudo cp -rf ../../debian/overlay/* ./

# overlay-firmware folder
sudo cp -rf ../../debian/overlay-firmware/* ./

# overlay-debug folder
# adb, video, camera  test file
if [ "$VERSION" == "debug" ]; then
	sudo cp -rf ../../debian/overlay-debug/* ./
	# adb
	if [[ "$ARCH" == "armhf" && "$VERSION" == "debug" ]]; then
		sudo cp -f ../../debian/overlay-debug/usr/local/share/adb/adbd-32 ./usr/bin/adbd
	elif [[ "$ARCH" == "arm64" && "$VERSION" == "debug" ]]; then
		sudo cp -f ../../debian/overlay-debug/usr/local/share/adb/adbd-64 ./usr/bin/adbd
	fi
fi

## hack the serial

# bt/wifi firmware
sudo mkdir -p ./system/lib/modules/
sudo mkdir -p ./vendor/etc
sudo find ../../kernel/drivers/net/wireless/rockchip_wlan/*  -name "*.ko" | \
    xargs -n1 -i sudo cp {} ./system/lib/modules/

echo -e "\033[36m Change root.....................\033[0m"
if [ "$ARCH" == "armhf" ]; then
	sudo cp /usr/bin/qemu-arm-static ./usr/bin/
elif [ "$ARCH" == "arm64"  ]; then
	sudo cp /usr/bin/qemu-aarch64-static ./usr/bin/
fi

if [ -f "../make.conf" ]; then
   sudo cp ../make.conf ./etc/portage/
   sudo cp ../fstab ./etc/
   sudo cp ../passwd ./etc/
   sudo cp ../shadow ./etc/
   sudo cp ../group ./etc/
   sudo cp ../inittab ./etc/
fi

# sudo cp --dereference /etc/resolv.conf ./etc/
# sudo mount --types proc /proc ./proc
# sudo mount --rbind /sys ./sys
# sudo mount --make-rslave ./sys
# sudo mount --rbind /dev ./dev
# sudo mount --make-rslave ./dev
# sudo mount --bind /run ./run
# sudo mount --make-slave ./run 

# cat << EOF | sudo chroot . /bin/bash

# source /etc/profile
# emerge --sync

# #chmod o+x /usr/lib/dbus-1.0/dbus-daemon-launch-helper
# chmod +x /etc/rc.local

# #---------------power management --------------
# emerge -vuNDk @world

# #---------------Rga--------------
# #https://github.com/tsukumijima/librga-rockchip
# #\${APT_INSTALL} /packages/rga/*.deb

# echo -e "\033[36m Setup Video.................... \033[0m"

# #https://github.com/rockchip-linux/mpp
# #\${APT_INSTALL} /packages/mpp/*
# #\${APT_INSTALL} /packages/gst-rkmpp/*.deb
# #\${APT_INSTALL} /packages/gstreamer/*.deb
# #\${APT_INSTALL} /packages/gst-plugins-base1.0/*.deb
# #\${APT_INSTALL} /packages/gst-plugins-bad1.0/*.deb
# #\${APT_INSTALL} /packages/gst-plugins-good1.0/*.deb
# #\${APT_INSTALL} /packages/gst-plugins-ugly1.0/*.deb

# #---------Camera---------
# echo -e "\033[36m Install camera.................... \033[0m"
# #\${APT_INSTALL} cheese v4l-utils
# #\${APT_INSTALL} /packages/libv4l/*.deb

# #---------Xserver---------
# #echo -e "\033[36m Install Xserver.................... \033[0m"
# #\${APT_INSTALL} /packages/xserver/*.deb

# #---------------Openbox--------------
# #echo -e "\033[36m Install openbox.................... \033[0m"
# #\${APT_INSTALL} /packages/openbox/*.deb

# #---------update chromium-----
# #\${APT_INSTALL} /packages/chromium/*.deb

# #------------------libdrm------------
# #echo -e "\033[36m Install libdrm.................... \033[0m"
# #\${APT_INSTALL} /packages/libdrm/*.deb

# #------------------libdrm-cursor------------
# #echo -e "\033[36m Install libdrm-cursor.................... \033[0m"
# #\${APT_INSTALL} /packages/libdrm-cursor/*.deb

# #------------------pcmanfm------------
# #https://wiki.archlinux.org/title/PCManFM
# #echo -e "\033[36m Install pcmanfm.................... \033[0m"
# #\${APT_INSTALL} /packages/pcmanfm/*.deb

# #------------------blueman------------
# #echo -e "\033[36m Install blueman.................... \033[0m"
# #\${APT_INSTALL} blueman
# #echo exit 101 > /usr/sbin/policy-rc.d
# #chmod +x /usr/sbin/policy-rc.d
# #\${APT_INSTALL} blueman
# #rm -f /usr/sbin/policy-rc.d

# #------------------rkwifibt------------
# #echo -e "\033[36m Install rkwifibt.................... \033[0m"
# #\${APT_INSTALL} /packages/rkwifibt/*.deb
# #ln -sf /system/etc/firmware /vendor/etc/

# if [ "$VERSION" == "debug" ]; then
# #------------------glmark2------------
# #echo -e "\033[36m Install glmark2.................... \033[0m"
# #\${APT_INSTALL} /packages/glmark2/*.deb
# fi

# #------------------rknpu2------------
# echo -e "\033[36m Install rknpu2.................... \033[0m"
# tar xvf /packages/rknpu2/*.tar -C /

# #------------------rktoolkit------------
# #https://github.com/rockchip-linux/rknn-toolkit
# #echo -e "\033[36m Install rktoolkit.................... \033[0m"
# #\${APT_INSTALL} /packages/rktoolkit/*.deb

# #------------------luckfox------------
# #echo -e "\033[36m Install luckfox.................... \033[0m"
# #\${APT_INSTALL} nano
# #\${APT_INSTALL} xinput
# #\${APT_INSTALL} i2c-tools wget gcc -y
# #\${APT_INSTALL} make
# #\${APT_INSTALL} gcc
# #\${APT_INSTALL} lua5.3
# #\${APT_INSTALL} minicom
# #\${APT_INSTALL} python3-smbus -y
# #\${APT_INSTALL} python3-pip
# #\${APT_INSTALL} python3-dev
# #\${APT_INSTALL} python3-setuptools
# #\${APT_INSTALL} lxlock
# #\${APT_INSTALL} bash-completion
# #\${APT_INSTALL} python3-numpy
# #https://opensource.com/article/17/11/taking-screen-captures-linux-command-line-scrot
# \${APT_INSTALL} scrot
# #pip3 install wheel
# #pip3 install Pillow
# #pip3 install python-periphery
# #pip3 install spidev


# #echo -e "\033[36m Install Chinese fonts.................... \033[0m"
# # Uncomment zh_CN.UTF-8 for inclusion in generation
# #sed -i 's/^# *\(zh_CN.UTF-8\)/\1/' /etc/locale.gen
# #echo "LANG=zh_CN.UTF-8" >> /etc/default/locale
# #sed -i 's/^# *\(en_US.UTF-8\)/\1/' /etc/locale.gen
# #echo "LANG=en_US.UTF-8" >> /etc/default/locale

# # Generate locale
# locale-gen

# # Export env vars
# # echo "export LC_ALL=zh_CN.UTF-8" >> ~/.bashrc
# # echo "export LANG=zh_CN.UTF-8" >> ~/.bashrc
# # echo "export LANGUAGE=zh_CN.UTF-8" >> ~/.bashrc
# #echo "export LC_ALL=en_US.UTF-8" >> ~/.bashrc
# #echo "export LANG=en_US.UTF-8" >> ~/.bashrc
# #echo "export LANGUAGE=en_US.UTF-8" >> ~/.bashrc

# #source ~/.bashrc

# #\${APT_INSTALL} ttf-wqy-zenhei xfonts-intl-chinese

# # HACK debian to fix bug
# #\${APT_INSTALL} fontconfig --reinstall

# #------------------pulseaudio---------
# #echo -e "\033[36m Install pulseaudio................. \033[0m"
# #cp /etc/pulse/daemon.conf /
# #cp /etc/pulse/default.pa /
# #yes|\${APT_INSTALL} /packages/pulseaudio/*.deb
# #mv /daemon.conf /default.pa /etc/pulse/
# #systemctl enable pulseaudio --global

# echo "VIDEO_CARDS=\"panfrost\"" >> /etc/portage/make.conf
# #cp /packages/libmali/libmali-*-x11*.deb /
# #cp -rf /packages/rga/ /
# #cp -rf /packages/rga2/ /
# #https://github.com/ayaromenok/MD/blob/master/Hardware/RkISP.md
# #cp -rf /packages/rkisp/*.deb /
# #https://gitlab.com/firefly-linux/external/camera_engine_rkaiq/-/tree/rk356x/firefly?ref_type=heads
# #cp -rf /packages/rkaiq/*.deb /

# #------remove unused packages------------
# #apt remove --purge -fy linux-firmware*

# # mark package to hold
# #apt list --installed | grep -v oldstable | cut -d/ -f1 | xargs apt-mark hold

# # mark rga package to unhold
# #apt-mark unhold librga2 librga-dev librga2-dbgsym

# #---------------Custom Script--------------
# #systemctl mask systemd-networkd-wait-online.service
# #systemctl mask NetworkManager-wait-online.service
# #rm /lib/systemd/system/wpa_supplicant@.service

# #---------------Clean--------------
# #if [ -e "/usr/lib/arm-linux-gnueabihf/dri" ] ;
# #then
# #        # Only preload libdrm-cursor for X
# #        sed -i "1aexport LD_PRELOAD=/usr/lib/arm-linux-gnueabihf/libdrm-cursor.so.1" /usr/bin/X
# #        cd /usr/lib/arm-linux-gnueabihf/dri/
# #        cp kms_swrast_dri.so swrast_dri.so /
# #        rm /usr/lib/arm-linux-gnueabihf/dri/*.so
# #        mv /*.so /usr/lib/arm-linux-gnueabihf/dri/
# #elif [ -e "/usr/lib/aarch64-linux-gnu/dri" ];
# #then
#         # Only preload libdrm-cursor for X
# #        sed -i "1aexport LD_PRELOAD=/usr/lib/aarch64-linux-gnu/libdrm-cursor.so.1" /usr/bin/X
# #        cd /usr/lib/aarch64-linux-gnu/dri/
# #        cp kms_swrast_dri.so swrast_dri.so /
# #        rm /usr/lib/aarch64-linux-gnu/dri/*.so
# #        mv /*.so /usr/lib/aarch64-linux-gnu/dri/
# #        rm /etc/profile.d/qt.sh
# #fi
# cd -

# #---------------Clean--------------
# #rm -rf /var/lib/apt/lists/*
# rm -rf /var/cache/
# rm -rf /packages/

# EOF

# sudo umount -R $TARGET_ROOTFS_DIR/dev
# sudo umount -R $TARGET_ROOTFS_DIR/sys
# sudo umount -R $TARGET_ROOTFS_DIR/proc
# sudo umount -R $TARGET_ROOTFS_DIR/run

