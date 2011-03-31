#!/bin/bash

# Format and mount partitions
format_partitions() {
rm -f /tmp/glis/format-partitions.log
start_format() {
case ${2} in
   ext2) mke2fs -q ${1} >>/tmp/glis/format-partitions.log 2>&1;;
   ext3) mke2fs -jq ${1} >>/tmp/glis/format-partitions.log 2>&1;;
   reiserfs) yes | mkreiserfs ${1} >>/tmp/glis/format-partitions.log 2>&1;;
   jfs) yes | mkfs.jfs ${1} >>/tmp/glis/format-partitions.log 2>&1;;
   xfs) mkfs.xfs -f ${1} >>/tmp/glis/format-partitions.log 2>&1;;
   swap) mkswap ${1} >>/tmp/glis/format-partitions.log 2>&1;;
esac
echo $? > /tmp/glis/format-partitions-exitstatus.tmp
}

swapoff `cat /proc/swaps | grep -v Filename | awk -F " " '{ print $1 }'` >/tmp/glis/format-partitions.log 2>&1
echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 2 ] && return

umount `cat /proc/mounts | grep "/mnt/gentoo" | awk -F " " '{ print $2 }' | sort -r` >/tmp/glis/format-partitions.log 2>&1
echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 2 ] && return

umount `cat /proc/mounts | grep "/dev/" | grep -v tmpfs | grep -v cdrom | grep -v cloop | awk -F " " '{ print $2 }' | sort -r` >/tmp/glis/format-partitions.log 2>&1
echo $? > /tmp/glis/format-partitions-exitstatus.tmp ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 2 ] && return

echo 0
start_format ${rootpart} ${roottype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 12
[ -n "${swappart}" ] && start_format ${swappart} swap ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return ; swapon ${swappart}
echo 25
[ -n "${bootpart}" ] && start_format ${bootpart} ${boottype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 37
[ -n "${homepart}" ] && start_format ${homepart} ${hometype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 50
[ -n "${rootuserpart}" ] && start_format ${rootuserpart} ${rootusertype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 62
[ -n "${tmppart}" ] && start_format ${tmppart} ${tmptype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 75
[ -n "${usrpart}" ] && start_format ${usrpart} ${usrtype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 87
[ -n "${varpart}" ] && start_format ${varpart} ${vartype} ; [ $(cat /tmp/glis/format-partitions-exitstatus.tmp) -ne 0 ] && return 
echo 100
}