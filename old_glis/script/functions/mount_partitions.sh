#!/bin/bash

mount_partitions() {
modprobe ide-floppy
mount ${rootpart} /mnt/gentoo >>/tmp/glis/format-partitions.log 2>&1
echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
if [ -n "${bootpart}" ]; then
   [ ! -d /mnt/gentoo/boot ] && mkdir /mnt/gentoo/boot
   [ ${boottype} == "reiserfs" ] && mount -o notail ${bootpart} /mnt/gentoo/boot >>/tmp/glis/format-partitions.log 2>&1
   [ ${boottype} != "reiserfs" ] && mount ${bootpart} /mnt/gentoo/boot >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
if [ -n "${homepart}" ]; then
   [ ! -d /mnt/gentoo/home ] && mkdir /mnt/gentoo/home
   mount ${homepart} /mnt/gentoo/home >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
if [ -n "${rootuserpart}" ]; then
   [ ! -d /mnt/gentoo/root ] && mkdir /mnt/gentoo/root
   mount ${rootuserpart} /mnt/gentoo/root >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
if [ -n "${tmppart}" ]; then
   [ ! -d /mnt/gentoo/tmp ] && mkdir /mnt/gentoo/tmp
   mount ${tmppart} /mnt/gentoo/tmp >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
if [ -n "${usrpart}" ]; then
   [ ! -d /mnt/gentoo/usr ] && mkdir /mnt/gentoo/usr
   mount ${usrpart} /mnt/gentoo/usr >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
if [ -n "${varpart}" ]; then
   [ ! -d /mnt/gentoo/var ] && mkdir /mnt/gentoo/var
   mount ${varpart} /mnt/gentoo/var >>/tmp/glis/format-partitions.log 2>&1
   echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return
fi
}