unpack_tarball()
{
source ${GLIS_CONFIG}

# Check for ftp:// and http://
if [ ! -z "$(echo "${TARBALL_LOCATION}" | grep -E "(^ftp|^http)://")" ]; then
   wget "${TARBALL_LOCATION}"
   if [ $? -ne 0 ]; then
      echo "!!! Error #0301: Error downloading tarball \"${TARBALL_LOCATION}\""
      return 1
   fi
   tarball=$(echo "${TARBALL_LOCATION}" | sed 's/.*\/\([^\/]*\)/\1/')
   tar -xapf ${tarball} -C /mnt/gentoo
   if [ $? -ne 0 ]; then
      echo "!!! Error #0302: Error unpacking tarball ${tarball}"
      return 1
   fi
elif [ -z "${TARBALL_LOCATION}" ] || [ ! -f ${TARBALL_LOCATION} ]; then
# If no tarball was set then use the default stage tarball from the cdrom
   tar -xapf /mnt/cdrom/stages/stage${INSTALL_STAGE}-*.tar.bz2 -C /mnt/gentoo/
   if [ $? -ne 0 ]; then
      echo "!!! Error #0303: Error unpacking stage tarball from cdrom."
      return 1
   fi
else
   tar -xapf ${TARBALL_LOCATION} -C /mnt/gentoo/
   if [ $? -ne 0 ]; then
      echo "!!! Error #0302: Error unpacking tarball \"${TARBALL_LOCATION}\""
      return 1
   fi
fi
}
