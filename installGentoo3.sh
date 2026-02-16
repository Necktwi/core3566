docker commit  gentooMuslLlvm  gentoo/stage3:musl-llvm-20260126-core3566
docker run --name gentooMuslLlvm2 -v ${HOME}/workspace/aarch64-gentoo-linux-musl:/usr/aarch64-gentoo-linux-musl -v ${HOME}/workspace:/workspace -v ${HOME}/workspace/gentooRepos:/var/db/repos -v ${HOME}/workspace/gentooRepos/gentoo/profiles:/usr/aarch64-gentoo-linux-musl/var/db/repos/gentoo/profiles -v ${HOME}/workpace/aarch64pkgdir:/usr/aarch64-gentoo-linux-musl/var/cache/binpkgs -it --privileged --device-cgroup-rule='c 189:* rmw' -v /dev/bus/usb:/dev/bus/usb gentoo/stage3:musl-llvm-20260126-core3566 /bin/bash
. /etc/profile
sudo login gowtham
cd workspace/linux
make LLVM=1 ARCH=arm64 DTC_FLAGS="-@" rockchip/rk3566-core3566.dtb rockchip/overlays/rk3566-nvme.dtbo
