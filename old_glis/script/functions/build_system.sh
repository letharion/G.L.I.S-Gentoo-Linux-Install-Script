#!/bin/bash

# Build or update system
build_system() {
start_build() {
# If user chose stage1 or stage2, then emerge system.  If stage3, update world.
if [ ${installstage} -eq 1 ] || [ ${installstage} -eq 2 ] ; then
   chroot_env_set "emerge system"
else
   chroot_env_set "emerge -u world"
fi
chroot /mnt/gentoo >> /tmp/glis/emerge-system.log 2>&1
echo $? > /tmp/glis/emerge-system-exitstatus.tmp
}

echo 0
rm -f /tmp/glis/emerge-system.log
start_build &
while [ ! -f /tmp/glis/emerge-system.log ]; do
   [ -f /tmp/glis/emerge-system-exitstatus.tmp ] && return 1
   sleep 2
done
while [ ! -f /tmp/glis/emerge-system-exitstatus.tmp ]; do
   totalmerges=`grep ">>> emerge (" /tmp/glis/emerge-system.log | head -1 | sed "s/.*of \(.*\)).*/\1/"`
   currentmerges=`grep -c "merged\." /tmp/glis/emerge-system.log`
   if [ "${totalmerges}" != "" ] && [ "${currentmerges}" != "" ]; then
      percent=`echo $(expr ${currentmerges} \* 95 / ${totalmerges})`
      echo ${percent}
   fi
   sleep 30
done
echo 98
if [ $(cat /tmp/glis/emerge-system-exitstatus.tmp) -eq 0 ]; then
   # Update config files
   chroot_env_set "echo \"-5\" | etc-update"
   chroot /mnt/gentoo >> /tmp/glis/emerge-system.log 2>&1
   etc_config "make.conf"
   etc_config "fstab"
   cat /tmp/glis/modules.autoload.tmp >> /mnt/gentoo/etc/modules.autoload
   rm -f /tmp/glis/modules.autoload.tmp
fi
echo 100
}