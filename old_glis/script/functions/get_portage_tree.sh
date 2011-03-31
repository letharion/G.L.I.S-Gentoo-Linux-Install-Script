#!/bin/bash

# Getting the current portage tree
get_portage_tree() {
start_sync() {
chroot /mnt/gentoo >> /tmp/glis/emerge-sync.log 2>&1
echo $? > /tmp/glis/emerge-sync-exitstatus.tmp
return $(cat /tmp/glis/emerge-sync-exitstatus.tmp)
}

echo 0
rm -f /tmp/glis/emerge-sync.log
chroot_env_set "emerge sync"
start_sync &
while [ ! -f /tmp/glis/emerge-sync.log ]; do
   [ -f /tmp/glis/emerge-sync-exitstatus.tmp ] && return 1
   sleep 2
done
while [ ! -f /tmp/glis/emerge-sync-exitstatus.tmp ]; do
   syncstatus=0
   [ $(grep -c ^app /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 3`
   [ $(grep -c ^dev /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 24`
   [ $(grep -c ^gnome /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 15`
   [ $(grep -c ^kde /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 2`
   [ $(grep -c ^media /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 2`
   [ $(grep -c ^metadata /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 8`
   [ $(grep -c ^net /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 13`
   [ $(grep -c ^sys /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 14`
   [ $(grep -c ^x11 /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 6`
   [ $(grep -c "Number of files:" /tmp/glis/emerge-sync.log) -gt 10 ] && syncstatus=`expr ${syncstatus} + 6`
   echo ${syncstatus}
   sleep 10
done
echo 100
}