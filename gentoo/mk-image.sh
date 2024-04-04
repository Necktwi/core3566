#!/bin/bash -ex

TARGET_ROOTFS_DIR=./binary
ROOTFSIMAGE=gentoo-rootfs.img
EXTRA_SIZE_MB=1300
IMAGE_SIZE_MB=$(( $(sudo du -sh -m ${TARGET_ROOTFS_DIR} | cut -f1) + ${EXTRA_SIZE_MB} ))


echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
   if [ "$NOCLEAN" ]; then
      echo "rootfs-image already build. skipping"
      exit 0
   fi
	rm ${ROOTFSIMAGE}
fi

sudo ./post-build.sh ${TARGET_ROOTFS_DIR}

dd if=/dev/zero of=${ROOTFSIMAGE} bs=1M count=0 seek=${IMAGE_SIZE_MB}

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE}

echo Rootfs Image: ${ROOTFSIMAGE}
