#!/bin/bash

unpack_tarball() {
# Start Extraction
cd /mnt/gentoo
if [ -f stage${installstage}-${arch}-${gentooversion}.tar.bz2 ] ; then
   tar -xvjpf stage${installstage}-${arch}-${gentooversion}.tar.bz2 >/tmp/glis/linecount.tmp 2>&1 &
else
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Stage ${installstage} tarball not found!" 6 80
   echo 1 > /tmp/glis/unpack-tarball-exitstatus.tmp && return
fi

linecount=0
while [ ${linecount} -lt ${linetotal} ] ; do
   while [ ! -s /tmp/glis/linecount.tmp ] ; do
      sleep 1
   done
   linecount=`grep --count . /tmp/glis/linecount.tmp`
   if [ "${linecount}" = "${lastlinecount}" ] ; then
      sleep 10
      linecount=`grep --count . /tmp/glis/linecount.tmp`
   fi
   if [ "${linecount}" = "${lastlinecount}" ] ; then
      sleep $(expr ${installstage} \* 100)
      linecount=`grep --count . /tmp/glis/linecount.tmp`
      if [ "${linecount}" = "${lastlinecount}" ] ; then
         killall -q tar
         cat /tmp/glis/linecount.tmp >> /tmp/glis/unpack-tarball.log
         rm -f /tmp/glis/linecount.tmp
         echo 1 > /tmp/glis/unpack-tarball-exitstatus.tmp && return
      fi
   fi
   percent=`expr ${linecount} \* 100 / ${linetotal}`
   echo ${percent}
   sleep 1
   lastlinecount=${linecount}
done
cat /tmp/glis/linecount.tmp >> /tmp/glis/unpack-tarball.log
rm -f /tmp/glis/linecount.tmp
echo 0 > /tmp/glis/unpack-tarball-exitstatus.tmp && return
}
