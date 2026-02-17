#!/bin/bash
. /workspace/installGentoo-1.sh
. /etc/profile
MKCNF=/etc/portage/make.conf

echoH "Merging build tools..."
emerge --sync
if ! grep DISTDIR /etc/portage/make.conf; then
	echo 'DISTDIR="/workspace/distdir"' >> $MKCNF
	echo 'PKGDIR="/workspace/pkgdir"' >> $MKCNF
	echo 'FEATURES="buildpkg"' >> $MKCNF
fi
cat /etc/portage/make.conf
emerge -vnk app-eselect/eselect-repository crossdev sys-fs/mtools sys-fs/dosfstools swig sys-devel/bc sudo sys-fs/dosfstools virtual/libudev dev-libs/libusb sys-apps/usbutils dev-python/pyelftools dev-vcs/git

lsusb

echoH "Making cross root..."
eselect repository create crossdev || true

if ! emerge -p cross_llvm-aarch64-gentoo-linux-musl/libcxx | grep "\[ebuild   R"; then
   echoH "Merging cross target..."
	crossdev --llvm -P "-vkn" --target ${TGTTPL}
fi

echoH "Extracting Gentoo..."
cd /usr/
cat ${TGTTPL}/etc/portage/make.conf
mv ${TGTTPL}/etc/portage/make.conf ./
cd /usr/${TGTTPL}/
# clean the folder before extracting stage3, delete all except the -not paths
find . -mindepth 1      -not -path "./var/cache/binpkgs*"      -not -path "./var/db/repos/gentoo/profiles*"      -delete 2>/dev/null || true

# wait for stage3 download to complete
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

CC="${TGTTPL}-clang" CXX="${TGTTPL}-clang++" CPP="${TGTTPL}-clang-cpp" ${TGTTPL}-emerge -vkn sudo app-admin/sysklogd
file ./usr/bin/sudo | grep aarch64 # check if merged sudo is aarch64 bin

echoH "Creating user..."
if username=$(getent passwd 1000); then
	username=$(echo $username | cut -d: -f1)
	userdel $username
fi
read -p "Enter username: " username
useradd $username
passwd $username
usermod $username -aG wheel
cp /etc/{passwd,group,shadow} /usr/${TGTTPL}/etc/
rsync -avpPh /home/$username /usr/${TGTTPL}/home/
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /usr/${TGTTPL}/etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

echoH "Making root folders..."
mkdir -p /usr/${TGTTPL}/{dev,proc,sys,run,mnt,media,var/log,var/run/faillock,tmp}

echoH "logging in as $username"
runuser -u $username -- /workspace/installGentoo2.sh
