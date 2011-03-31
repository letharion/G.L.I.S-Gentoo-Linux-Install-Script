
# Set up the system so that we can begin installing gentoo to it. This
# includes writing resolv.conf and make.conf (portage options) and
# appropriatly mounting /proc and /dev.
prepare_system()
{
source ${GLIS_CONFIG}
source functions/000-write_config.sh

ebegin "Setting up the new system..."
# Set CHROOT environment
echo -e "env-update\nsource /etc/profile" > /mnt/gentoo/root/.bashrc
if [ $? -ne 0 ]; then
   eend 1
   echo "!!! Error #0401: Could not set .bashrc parameters."
   return 1
fi

cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf
if [ $? -ne 0 ]; then
   eend 1
   echo "!!! Error #0402: Could not copy resolv.conf to new system."
   return 1
fi

# Set proc and dev mount points
[ $(mount | grep -c "/mnt/gentoo/proc") -gt 0 ] && umount /mnt/gentoo/proc
mount -t proc none /mnt/gentoo/proc
if [ $? -ne 0 ]; then
   eend 1
   echo "!!! Error #0402: Could not mount /proc in new system."
   return 1
fi

[ ! -d /mnt/gentoo/dev ] && mkdir /mnt/gentoo/dev
[ $(mount | grep -c "/mnt/gentoo/dev") -gt 0 ] && umount /mnt/gentoo/dev
mount --rbind /dev /mnt/gentoo/dev
if [ $? -ne 0 ]; then
   eend 1
   echo "!!! Error #0403: Could not mount /dev in new system."
   return 1
fi
eend 0

# Config make.conf
ebegin "Setting up portage options..."
etc_config "make.conf"
if [ $? -ne 0 ]; then
   eend 1
   echo "!!! Error #0404: Error modifying make.conf."
   return 1
fi
eend 0

return 0
}
