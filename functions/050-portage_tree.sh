portage_tree()
{
source ${GLIS_CONFIG}

if [ "${PORTAGE_TREE}" == "" ]; then
   # Since no portage tree was selected we will check to make sure one
   # currently exists and exit if it does.
   if [ -d /usr/portage ] || [ -h /usr/portage ]; then
      return 0
   else
      echo "!!! Error #0501: No portage tree exists."
      return 1
   fi
elif [ $(echo ${PORTAGE_TREE} | grep -ic "^SYNC$") -eq 1 ]; then
   # Run an emerge sync
   chroot /mnt/gentoo emerge sync
   if [ $? -ne 0 ]; then
      echo "!!! Error #0502: Emerge sync failed."
      return 1
   fi
elif [ ! -z "$(echo "${PORTAGE_TREE}" | grep -E "(^ftp|^http)://")" ]; then
   wget "${PORTAGE_TREE}"
   if [ $? -ne 0 ]; then
      echo "!!! Error #0301: Error downloading tarball \"${PORTAGE_TREE}\""
      return 1
   fi
   tarball=$(echo "${PORTAGE_TREE}" | sed 's/.*\/\([^\/]*\)/\1/')
   tar -xvaf ${tarball} -C /mnt/gentoo/usr
   if [ $? -ne 0 ]; then
      echo "!!! Error #0302: Error unpacking tarball ${tarball}"
      return 1
   fi
else
   # Unpack the specified portage snapshot.
   if [ -e ${PORTAGE_TREE} ]; then
      tar -xvjf ${PORTAGE_TREE} -C /mnt/gentoo/usr
      if [ $? -ne 0 ]; then
         echo "!!! Error #0503: Error unpacking portage snapshot ${PORTAGE_TREE}."
         return 1
      fi
   else
      echo "!!! Error #0504: The portage snapshot ${PORTAGE_TREE} could not be found."
      return 1
   fi
fi

[ -d /mnt/cdrom/distfiles ] && cp -vR /mnt/cdrom/distfiles /mnt/gentoo/usr/portage/distfiles
[ -d /mnt/cdrom/packages ] && cp -va /mnt/cdrom/packages /mnt/gentoo/usr/portage/packages

return 0
}
