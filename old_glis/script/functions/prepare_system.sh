#!/bin/bash

prepare_system() {
# Detect hardware modules and add them to a temp file
echo 1
grep DRIVER /etc/sysconfig/knoppix | awk -F = '{ print $2 }' | sed "s/\"//g" | grep -v unknown | sort | uniq > /tmp/glis/modules.autoload.tmp
echo 25

# Remount proc and dev inside the chroot environment
umount /mnt/gentoo/proc >> /dev/null 2>&1
mount -t proc proc /mnt/gentoo/proc >> /dev/null 2>&1
umount /mnt/gentoo/dev >> /dev/null 2>&1
mount --bind /dev /mnt/gentoo/dev >> /dev/null 2>&1
echo 50

# Copy DNS info to chroot env
rm -f /mnt/gentoo/etc/resolv.conf
cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf
echo 75

# Configure /etc/make.conf
etc_config "make.conf"
echo 100
}
