#!/bin/bash

download_tarball() {
cd /mnt/gentoo/
# Download tarball
wget -o /tmp/glis/unpack-tarball.log -b ${mirrorchoice}releases/${gentooversion}/${arch}/${arch}/stages/stage${installstage}-${arch}-${gentooversion}.tar.bz2 >> /dev/null 2>&1

# Monitor download
downloadpercent=0
while [ "${downloadpercent}" != "100" ] ; do
   i=0
   while [ ! -s /tmp/glis/unpack-tarball.log ] ; do
      sleep 1
      i=`expr ${i} + 1`
      if [ ${i} -eq 100 ]; then
         killall -q wget
         rm -f /mnt/gentoo/stage${installstage}-${arch}-${gentooversion}.tar.bz2
         echo 1 > /tmp/glis/unpack-tarball-exitstatus.tmp
         return
      fi
   done
   downloadpercent=`grep % /tmp/glis/unpack-tarball.log | tail -1 | sed 's/.* \(.*\)%.*/\1/'`
   [ "${downloadpercent}" = "" ] && downloadpercent=0
   echo "${downloadpercent}"
   sleep 3
   if [ "${downloadpercent}" = "${lastdownloadpercent}" ] ; then
      i=0
      while [ "${downloadpercent}" = "${lastdownloadpercent}" ] ; do
         downloadstatus=`grep -c ERROR /tmp/glis/unpack-tarball.log`
         downloadpercent=`grep % /tmp/glis/unpack-tarball.log | tail -1 | sed 's/.* \(.*\)%.*/\1/'`
         echo "${downloadpercent}"
         sleep ${installstage}
         i=`expr ${i} + 1`
         if [ ${i} -eq 100 ] || [ "${downloadstatus}" != "0" ]; then
            killall -q wget
            rm -f /mnt/gentoo/stage${installstage}-${arch}-${gentooversion}.tar.bz2
            echo 1 > /tmp/glis/unpack-tarball-exitstatus.tmp
            return
         fi
      done
   fi
   lastdownloadpercent=${downloadpercent}
done
echo 0 > /tmp/glis/unpack-tarball-exitstatus.tmp
}