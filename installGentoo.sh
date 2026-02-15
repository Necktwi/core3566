#!/bin/bash
set -euo pipefail
set -x
. /workspace/installGentoo-1.sh
. /etc/profile
MKCNF=/etc/portage/make.conf
# if ! grep FEATURES $MKCNF; then
# 	echo 'FEATURES="getbinpkg binpkg-request-signature"' >> $MKCNF;
# elif ! grep getbinpgk $MKCNF; then
# 	sed -i '/^FEATURES=/s/"$/ getbinpkg binpkg-request-signature"/' $MKCNF
# fi

echoH "Merging build tools..."
emerge --sync
if ! grep DISTDIR /etc/portage/make.conf; then
	echo 'DISTDIR="/workspace/distdir"' >> $MKCNF
	echo 'PKGDIR="/workspace/pkgdir"' >> $MKCNF
	echo 'FEATURES="buildpkg"' >> $MKCNF
fi
cat /etc/portage/make.conf
emerge -vnk app-eselect/eselect-repository crossdev sudo sys-fs/mtools sys-fs/dosfstools swig sys-devel/bc sudo sys-fs/dosfstools virtual/libudev dev-libs/libusb sys-apps/usbutils dev-python/pyelftools dev-vcs/git

lsusb

# eselect repository enable gentoo
# ESELREPCNF=/etc/portage/repos.conf/eselect-repo.conf
# if [ ! -d /etc/portage/repos.conf ]; then
# 	mkdir -p /etc/portage/repos.conf
# 	tee ${ESELREPOCONF} > /dev/null <<EOF
# [DEFAULT]
# main-repo = gentoo
# [gentoo]
# location = /var/db/repos/gentoo
# sync-type = git
# sync-uri = https://github.com/gentoo-mirror/gentoo.git
# auto-sync = yes
# EOF
# 	emerge --sync
# elif [ -f ${ESELREPCNF} ] && grep 'sync-type = rsync' ${ESELREPCNF}; then
# 	sed -i 's/sync-type = rsync/sync-type = git/' ${ESELREPCNF}
# 	sed -i 's/^sync-uri.*/sync-uri = https:\/\/github.com\/gentoo\/gentoo.git/' ${ESELREPCNF}
# 	emerge --sync
# fi

echoH "Making cross root..."
if ! grep cross_llvm-aarch64 /etc/portage/repos.conf/eselect-repo.conf; then
	eselect repository create cross_llvm-aarch64-gentoo-linux-musl
	tee -a /etc/portage/repos.conf/eselect-repo.conf > /dev/null <<EOF
priority = 10
masters = gentoo
auto-sync = no
EOF
fi

if ! aarch64-gentoo-linux-musl-clang --version; then
	crossdev -oS cross_llvm-aarch64-gentoo-linux-musl --llvm -P "-vkn" --target aarch64-gentoo-linux-musl
fi

echoH "Extracting Gentoo..."
cd /usr/
mv aarch64-gentoo-linux-musl/etc/portage/make.conf ./
cd aarch64-gentoo-linux-musl/
find . -mindepth 1      -not -path "./var/cache/binpkgs*"      -not -path "./var/db/repos/gentoo/profiles*"      -delete 2>/dev/null || true
while ! [ -f /workspace/stage3-arm64-musl-llvm.tar.xz ]; do
	echoH "Waiting for stage3-arm64-musl-llvm.tar.xz..."
	sleep 5;
done
tar -xJpf /workspace/stage3-arm64-musl-llvm.tar.xz  --exclude=dev --skip-old-files
if ! grep ROOT= etc/portage/make.conf; then
	sed -i '/^CHOST=/d' etc/portage/make.conf
	grep CBUILD= ../make.conf >> etc/portage/make.conf
	grep CHOST= ../make.conf >> etc/portage/make.conf
	grep ROOT= ../make.conf >> etc/portage/make.conf
	grep FEATURES= ../make.conf >> etc/portage/make.conf
	grep PKGDIR= ../make.conf >> etc/portage/make.conf
	grep PORTAGE_TMPDIR= ../make.conf >> etc/portage/make.conf
	echo "VIDEO_CARDS='panfrost'" >> etc/portage/make.conf
	rm ../make.conf
fi
PROFILE=/usr/aarch64-gentoo-linux-musl/etc/portage/make.profile
aarch64-gentoo-linux-musl-emerge -vkn sudo

echoH "Creating user..."
if username=$(getent passwd 1000); then
	username=$(echo $username | cut -d: -f1)
	userdel $username
fi
read -p "Enter username: " username
useradd $username
passwd $username
usermod $username -aG wheel
cp /etc/{passwd,group,shadow} /usr/aarch64-gentoo-linux-musl/etc/
rsync -avpPh /home/$username /usr/aarch64-gentoo-linux-musl/home/
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /usr/aarch64-gentoo-linux-musl/etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

echoH "Making root folders..."
mkdir -p /usr/aarch64-gentoo-linux-musl/{dev,proc,sys,run,mnt,media,var/log,var/run/faillock,tmp}

echoH "logging in as $username"
runuser -u $username -- /workspace/installGentoo2.sh
