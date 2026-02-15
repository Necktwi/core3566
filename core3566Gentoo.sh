#!/bin/bash
set -x
. installGentoo-1.sh
if [ "${1:-default}" == "clean" ]; then
	docker rm gentooMuslLlvm
	rm -rf ~/workspace/u-boot
	rm -rf ~/workspace/linux
	rm -rf ~/workspace/rkbin
	sudo rm -rf ~/workspace/aarch64-gentoo-linux-musl
fi
set -euo pipefail  # Exit on error, unset variables, and pipeline failures
echoH "Connect ur Core3566, preparing to detect it..."
sudo tee /etc/udev/rules.d/99-rockchip.rules > /dev/null <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger

mkdir -p ~/workspace/aarch64-gentoo-linux-musl
mkdir -p ~/workspace/gentooRepos
mkdir -p ~/workspace/distfiles
cd ~/workspace
if ! [ -f stage3-arm64-musl-llvm.tar.xz ]; then
	echoH "Downloading Gentoo stage-3 in background..."
	curl -LO https://distfiles.gentoo.org/releases/arm64/autobuilds/20260201T231555Z/stage3-arm64-musl-llvm-20260201T231555Z.tar.xz >/dev/null 2>&1 && mv stage3-arm64-musl-llvm*.tar.xz stage3-arm64-musl-llvm.tar.xz &
else
	echoH "stage3-arm64-musl-llvm.tar.xz already here."
fi
echoH "Spinning up Gentoo container..."
docker run --name gentooMuslLlvm -v ${HOME}/workspace/aarch64-gentoo-linux-musl:/usr/aarch64-gentoo-linux-musl -v ${HOME}/workspace:/workspace -v ${HOME}/workspace/gentooRepos:/var/db/repos -v ${HOME}/workspace/gentooRepos/gentoo/profiles:/usr/aarch64-gentoo-linux-musl/var/db/repos/gentoo/profiles -v ${HOME}/workspace/aarch64pkgdir:/usr/aarch64-gentoo-linux-musl/var/cache/binpkgs -it --privileged --device-cgroup-rule='c 189:* rmw' -v /dev/bus/usb:/dev/bus/usb gentoo/stage3:musl-llvm-20260126 /bin/bash /workspace/installGentoo.sh || docker start -ai gentooMuslLlvm
