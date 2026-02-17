#!/bin/bash
if [ "${1:-default}" == "clean" ]; then
	docker rm gentooMuslLlvm
	rm -rf ~/workspace/u-boot
	rm -rf ~/workspace/linux
	rm -rf ~/workspace/rkbin
	sudo rm -rf ~/workspace/aarch64-gentoo-linux-musl
   rm installGentoo*
fi
if ! [ -f installGentoo-1.sh ]; then
   curl -LO https://raw.githubusercontent.com/Necktwi/core3566/refs/heads/master/installGentoo-1.sh
   chmod +x installGentoo-1.sh
fi
. installGentoo-1.sh
set -euo pipefail  # Exit on error, unset variables, and pipeline failures
echoH "Connect ur Core3566, preparing to detect it..."
sudo tee /etc/udev/rules.d/99-rockchip.rules > /dev/null <<EOF
SUBSYSTEM=="usb", ATTR{idVendor}=="2207", MODE="0666"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger

echoH "Creating required folders..."
# rootfs folder
mkdir -p ~/workspace/${TGTTPL}
# gentoo ebuilds repo
mkdir -p ~/workspace/gentooRepos
# upstream tar balls are stored here
mkdir -p ~/workspace/distfiles
cd ~/workspace

if ! [ -f installGentoo.sh ]; then
	echoH "Downloading build scripts..."
	curl -LO https://raw.githubusercontent.com/Necktwi/core3566/refs/heads/master/installGentoo.sh
	curl -LO https://raw.githubusercontent.com/Necktwi/core3566/refs/heads/master/installGentoo2.sh
   chmod +x installGentoo*
fi
if ! [ -f stage3-arm64-musl-llvm.tar.xz ]; then
	echoH "Downloading Gentoo stage-3 in background..."
	curl -LO https://distfiles.gentoo.org/releases/arm64/autobuilds/20260201T231555Z/stage3-arm64-musl-llvm-20260201T231555Z.tar.xz >/dev/null 2>&1 && mv stage3-arm64-musl-llvm*.tar.xz stage3-arm64-musl-llvm.tar.xz &
else
	echoH "stage3-arm64-musl-llvm.tar.xz already here."
fi
echoH "Spinning up Gentoo container..."
docker run --name gentooMuslLlvm -v ${HOME}/workspace/${TGTTPL}:/usr/${TGTTPL} -v ${HOME}/workspace:/workspace -v ${HOME}/workspace/gentooRepos:/var/db/repos -v ${HOME}/workspace/gentooRepos/gentoo/profiles:/usr/${TGTTPL}/var/db/repos/gentoo/profiles -v ${HOME}/workspace/aarch64pkgdir:/usr/${TGTTPL}/var/cache/binpkgs -it --privileged --device-cgroup-rule='c 189:* rmw' -v /dev/bus/usb:/dev/bus/usb gentoo/stage3:musl-llvm-20260126 /bin/bash /workspace/installGentoo.sh || docker start -ai gentooMuslLlvm
