#!/bin/bash

# Bootstrap system
bootstrap_system() {
start_bootstrap() {
# If user chose stage1, then bootstrap
if [ ${installstage} -eq 1 ] ; then
   chroot_env_set "/usr/portage/scripts/bootstrap.sh"
   chroot /mnt/gentoo >> /tmp/glis/emerge-bootstrap.log 2>&1
   echo $? > /tmp/glis/emerge-bootstrap-exitstatus.tmp
else
   echo 0 > /tmp/glis/emerge-bootstrap-exitstatus.tmp
fi
}
echo 1
rm -f /tmp/glis/emerge-bootstrap.log
start_bootstrap &
while [ ! -f /tmp/glis/emerge-bootstrap.log ]; do
   [ -f /tmp/glis/emerge-bootstrap-exitstatus.tmp ] && return 1
   sleep 2
done
while [ ! -f /tmp/glis/emerge-bootstrap-exitstatus.tmp ]; do
   totalmerges=11
   currentmerges=`grep -c "merged\." /tmp/glis/emerge-bootstrap.log`
   percent=`echo $(expr ${currentmerges} \* 95 / ${totalmerges})`
   echo ${percent}
   sleep 30
done
echo 100
}