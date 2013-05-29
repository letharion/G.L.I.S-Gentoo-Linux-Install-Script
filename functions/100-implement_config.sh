implement_config()
{
source ${GLIS_CONFIG}

# Set root password

if [ "${ROOT_PASSWORD_HASH}" == "" ]; then
   echo "!!! Error #1001: ROOT_PASSWORD_HASH was not set in config file."
   return 1
fi

echo "root:${ROOT_PASSWORD_HASH}" | chroot /mnt/gentoo chpasswd
if [ $? -ne 0 ]; then
   echo "!!! Error #1002: Could not set root password."
   return 1
fi

# Set up extra users
for (( i=0 ; ${i} < ${#USER_NAME[@]} ; i++ )); do
   [ -z "${USER_GROUPS[${i}]}" ] && USER_GROUPS[${i}]="users"
   [ -z "${USER_SHELL[${i}]}" ] && USER_SHELL[${i}]="/bin/bash"
   [ -z "${USER_HOME[${i}]}" ] && USER_HOME[${i}]="/home/${USER_NAME[${i}]}"
   [ -z "${USER_COMMENT[${i}]}" ] && USER_COMMENT[${i}]="Added by GLIS"
   [ ! -z "${USER_UID[${i}]}" ] && USER_UID[${i}]="-u ${USER_UID[${i}]}"

   chroot /mnt/gentoo useradd -c "${USER_COMMENT[${i}]}" -d ${USER_HOME[${i}]}\
      -G ${USER_GROUPS[${i}]} -m -s ${USER_SHELL[${i}]} ${USER_UID[${i}]} \
      -p ${USER_PASSWORD_HASH[${i}]} ${USER_NAME[${i}]}
	 
   if [ $? -ne 0 ]; then
      echo "!!! Error #1003: Could not add user ${USER_NAME[${i}]}."
      return 1
   fi
done

# Setup config files
echo "-5" | chroot /mnt/gentoo etc-update > /dev/null
etc_config "rc.conf"
etc_config "make.conf"
etc_config "fstab"

#---------------#
# Network Setup #
#---------------#

# Setup hostname and domain names
[ "${HOSTNAME}" == "" ] && HOSTNAME="localhost"
[ "${HOSTNAME}" == "DHCP" ] && HOSTNAME="$(cat /etc/dhcpc/dhcp*.info | grep HOSTNAME | sort | uniq | tail -n 1 | cut -d = -f2 | sed "s/'//g")"
echo ${HOSTNAME} > /mnt/gentoo/etc/hostname || return 1
[ "${DOMAIN}" == "" ] && DOMAIN="localdomain"
[ "${DOMAIN}" == "DHCP" ] && DOMAIN="$(cat /etc/dhcpc/dhcp*.info | grep DOMAIN | sort | uniq | tail -n 1 | cut -d = -f2 | sed "s/'//g")"
echo ${DOMAIN} > /mnt/gentoo/etc/dnsdomainname || return 1
[ "${NISDOMAIN}" == "DHCP" ] && NISDOMAIN="$(cat /etc/dhcpc/dhcp*.info | grep NISDOMAIN | sort | uniq | tail -n 1 | cut -d = -f2 | sed "s/'//g")"
[ "${NISDOMAIN}" != "" ] && echo ${NISDOMAIN} > /mnt/gentoo/etc/nisdomainname

#'
# Setup /etc/hosts
echo -e "127.0.0.1\t${HOSTNAME}.${DOMAIN}\t${HOSTNAME}" >> /mnt/gentoo/etc/hosts

# Setup each network interface
if [ ${#IFACE_POST[@]} -gt 0 ]; then
   rm -f /mnt/gentoo/etc/conf.d/net
   for (( i=0 ; ${i} < ${#IFACE_POST[@]} ; i++ )); do
      # Copy the init scripts
      [ "${IFACE_POST[${i}]}" != "eth0" ] && ln -s /mnt/gentoo/etc/init.d/net.eth0 /mnt/gentoo/etc/init.d/net.${IFACE_POST[${i}]}
	  
      # If applicable, add iface to runlevel default
      [ "${IFACE_BOOT[${i}]}" != "0" ] && chroot /mnt/gentoo rc-update add net.${IFACE_POST[${i}]} default
   
      if [ "${IFACE_IP_POST[${i}]}" != "" ] && \
         [ "${IFACE_BROADCAST_POST[${i}]}" != "" ] && \
         [ "${IFACE_NETMASK_POST[${i}]}" != "" ]; then
         echo "iface_${IFACE_POST[${i}]}=\"${IFACE_IP_POST[${i}]} broadcast ${IFACE_BROADCAST_POST[${i}]} netmask ${IFACE_NETMASK_POST[${i}]}\"" >> /mnt/gentoo/etc/conf.d/net
         [ "${IFACE_GATEWAY_POST[${i}]}" != "" ] && echo "gateway=\"${IFACE_POST[${i}]}/${IFACE_GATEWAY_POST[${i}]}\"" >> /mnt/gentoo/etc/conf.d/net
      else
         echo "iface_${IFACE_POST[${i}]}=\"dhcp\"" >> /mnt/gentoo/etc/conf.d/net
         # Set dhcp timeout to 10 seconds
         echo "dhcpcd_${IFACE_POST[${i}]}=\"-t 10\"" >> /mnt/gentoo/etc/conf.d/net
      fi

      # If exists, add iface alias
      [ "${IFACE_ALIAS[${i}]}" != "" ] && echo alias_${IFACE_POST[${i}]}="${IFACE_ALIAS[${i}]}" >> /mnt/gentoo/etc/conf.d/net

      # Setup custom alias netmasks and broadcasts
      [ "${IFACE_ALIAS_BROADCAST[${i}]}" != "" ] && echo "broadcast_${IFACE_POST[${i}]}=\"${IFACE_ALIAS_BROADCAST[${i}]}\"" >> /mnt/gentoo/etc/conf.d/net
      [ "${IFACE_ALIAS_NETMASK[${i}]}" != "" ] && echo "netmask_${IFACE_POST[${i}]}=\"${IFACE_ALIAS_NETMASK[${i}]}\"" >> /mnt/gentoo/etc/conf.d/net
   done
   
   if [ "$(echo "${NAMESERV_POST}" | cut -d " " -f1)" != "" ]; then
      rm -f /mnt/gentoo/etc/resolv.conf
      for nameserver in ${NAMESERV_POST}; do
         echo "nameserver $nameserver" >> /mnt/gentoo/etc/resolv.conf 
      done
      echo "search ${DOMAIN}" >> /mnt/gentoo/etc/resolv.conf
      echo "domain ${DOMAIN}" >> /mnt/gentoo/etc/resolv.conf	 
   fi
fi


####################################################
# How do you set up proxy info for the new system? #
# I can't find this in the install docs...         #
####################################################
[ "${HTTP_PROXY_POST}" != "" ] && echo "export http_proxy=\"${HTTP_PROXY_POST}\"" >> /etc/profile
[ "${FTP_PROXY_POST}" != "" ] && echo "export ftp_proxy=\"${FTP_PROXY_POST}\"" >> /etc/profile
[ "${RSYNC_PROXY_POST}" != "" ] && echo "export RSYNC_PROXY=\"${RSYNC_PROXY_POST}\"" >> /etc/profile

#-------------------#
# Config Bootloader #
#-------------------#

# Get the /boot partition (if there is no /boot partition, get the / partition)
BOOT_PARTITION="$(mount | grep "/mnt/gentoo/boot " | cut -d " " -f1)"
[ "${BOOT_PARTITION}" == "" ] && BOOT_PARTITION="$(mount | grep "/mnt/gentoo " | cut -d " " -f1)"

# Bootloader specific stuff
if [ "${BOOT_LOADER}" != "lilo" ] && [ "${BOOT_LOADER}" != "LILO" ] ; then
   
   # Function to get the grub style output for a device
   get_grub_style() {
   # Check to make sure the device exists
   if [ ! -e $1 ]; then
      echo "!!! Error #1005: Boot device $1 could not be found."
      return 1
   fi
   
   # Generate up to date device map
   [ -f /mnt/gentoo/tmp/device.map ] && rm -f /mnt/gentoo/tmp/device.map
   echo -e "quit\n" > /tmp/grub.batch
   chroot /mnt/gentoo grub --batch --no-floppy --device-map=/tmp/device.map < /tmp/grub.batch > /tmp/grub.log 2>&1
   rm -f /tmp/grub.batch
   if [ "$(grep "Error [0-9]*: " /tmp/grub.log)" != "" ]; then
      cat /tmp/grub.log 1>&2
      rm -f /tmp/grub.log
      rm -f /mnt/gentoo/tmp/device.map
      echo "!!! Error #1006: Grub could not be started."
      return 1
   fi
   rm -f /tmp/grub.log
   
   # Check for duplicates in the device map
   dup=`sed -n '/^([fh]d[0-9]*)/s/\(^(.*)\).*/\1/p' /mnt/gentoo/tmp/device.map | sort | uniq -d | sed -n 1p`
   if [ -n "${dup}" ]; then
      rm -f /mnt/gentoo/tmp/device.map
      echo "!!! Error #1007: The drive ${dup} is defined multiple times in the device map."
      return 1
   fi

   # Convert complex device notation (ie /dev/hda1) into just the partition
   # number (on the drive)
   part=`echo "$1" | sed -n -e "s/\/dev\/[sh]d[a-z]\([0-9]\)/\1/p" -e "s/\/dev\/discs\/disc[0-9]\/[pd][ai][rs][tc]\([0-9]\)/\1/p"`
   # Convert complex device notation (ie /dev/hda1) into just the drive
   # notation (/dev/hda)
   tmp_disk=`echo "$1" | sed -e "s/\(\/dev\/[sh]d[a-z]\)[0-9]*/\1/" -e "s/\(\/dev\/[sh]d[a-z]\)$/\1/" -e "s/\(\/dev\/discs\/disc[0-9]*\)\/[pd][ai][rs][tc].*/\1/"`

   # Get real disk info (reading the links)
   disk=`readlink $tmp_disk | sed -e "s/.*\(ide\/host[0-9]*\/bus[0-9]*\/target[0-9]*\/lun[0-9]*\).*/\/dev\/\1\/disc/" -e "s/.*\(scsi\/host[0-9]*\/bus[0-9]*\/target[0-9]*\/lun[0-9]*\).*/\/dev\/\1\/disc/"`

   # Find the drive in grub notation
   grub_drive=`grep ${disk} /mnt/gentoo/tmp/device.map | sed "s/(\(.*\)).*/\1/"`
   rm -f /mnt/gentoo/tmp/device.map

   # If the function was called with a partition, echo the partition in
   # grub notation.
   if [ "${part}" != "" ]; then
      grub_part=`expr ${part} - 1`
      grub_style="${grub_drive},${grub_part}"
      echo "${grub_style}"
      return 0
	  
   # If the function was called with a drive, echo the drive in grub notation.
   else
      echo "${grub_drive}"
      return 0
   fi
   }

   # Convert the BOOT_PARTITION to grub style
   GRUB_BOOT="$(get_grub_style "${BOOT_PARTITION}")"
   [ $? -ne 0 ] && return 1
   
   # Choose where to install the bootloader (MBR or BOOT_PARTITION)
   if [ ${BOOT_LOADER_MBR} -ne 0  ]; then
      GRUB_INSTALL="hd0"
   else
      GRUB_INSTALL="${GRUB_BOOT}"
   fi
   
   # Config grub
   rm -f /mnt/gentoo/boot/grub/menu.lst
   echo -e "default 0\ntimeout 30\nsplashimage=(${GRUB_BOOT})/boot/grub/splash.xpm.gz\n\ntitle=Gentoo Linux\nroot (${GRUB_BOOT})\nkernel (${GRUB_BOOT})/boot/vmlinuz root=$(mount | grep "/mnt/gentoo " | cut -d " " -f1)" > /mnt/gentoo/boot/grub/grub.conf
   if [ $? -ne 0 ]; then
      echo "!!! Error #1008: Could not write grub.conf."
      return 1
   fi
   ln -s /boot/grub/grub.conf /mnt/gentoo/boot/grub/menu.lst

   # Add initrd to grub.conf?
   [ -e /mnt/gentoo/boot/initrd ] && echo -e "initrd (${GRUB_BOOT})/boot/initrd" >> /mnt/gentoo/boot/grub/grub.conf
         
   # Install grub
   echo -e "root (${GRUB_BOOT})\nsetup (${GRUB_INSTALL})\nquit\n" > /tmp/grub.batch
   chroot /mnt/gentoo grub --no-floppy --batch < /tmp/grub.batch > /tmp/grub.log 2>&1
   rm -f /tmp/grub.batch
   if grep "Error [0-9]*: " /tmp/grub.log >/dev/null; then
      cat /tmp/grub.log 1>&2
      rm -f /tmp/grub.log
      rm -f /mnt/gentoo/tmp/device.map
      echo "!!! Error #1006: Grub could not be started."
      return 1
   fi
   rm -f /tmp/grub.log
else
   
   if [ ${BOOT_LOADER_MBR} -ne 0 ]; then
   
      # If /dev/discs/disc0 is not there, we can't tell what the first disc was
      if [ ! -e /dev/discs/disc0 ]; then
         echo "!!! Error #1009: GLIS can't determine first disc."
         return 1
      fi
   
      # Read the link from the first disc
      FIRST_DRIVE_LINK="$(readlink /dev/discs/disc0 | sed "s/.*\/\(.*\)\/host\([0-9]\)\/bus\([0-9]\)\/target\([0-9]\)\/lun\([0-9]\).*/\1\2\3\4\5/")"
   
      # Get a list of all the /dev/
      ls --color=none /dev/[hs]d[a-z] >/tmp/drive_list 2>/dev/null
   
      # Loop to find the short name for the first drive
      while read line ; do
         SHORTNAME_LINK="$(readlink $line | sed "s/\(.*\)\/host\([0-9]\)\/bus\([0-9]\)\/target\([0-9]\)\/lun\([0-9]\).*/\1\2\3\4\5/")"
      
         # If the link of the short name matches the link of the first drive, then echo it and return
         if [ "${SHORTNAME_LINK}" == "${FIRST_DRIVE_LINK}" ]; then
            LILO_INSTALL="$line"
            break
         fi
      done < /tmp/drive_list
   
      # If LILO_INSTALL is NULL, an error occured
      [ "${LILO_INSTALL}" == "" ] && return 1
   else
      # If MBR is not desired, install to the boot (or root) partition
      LILO_INSTALL="${BOOT_PARTITION}"
   fi
   
   # Config lilo
   echo -e "boot=${LILO_INSTALL}\nmap=/boot/map\ninstall=/boot/boot.b\nprompt\ntimeout=50\nlba32\ndefault=linux\n\nimage=/boot/vmlinuz\n\tlabel=linux\n\tread-only\n\troot=$(mount | grep "/mnt/gentoo " | cut -d " " -f1)" > /mnt/gentoo/etc/lilo.conf
   if [ $? -ne 0 ]; then
      echo "!!! Error #1010: Could not write lilo.conf."
      return 1
   fi

   # Add initrd to lilo.conf?
   [ -e /mnt/gentoo/boot/initrd ] && echo -e "\tinitrd=/boot/initrd" >> /mnt/gentoo/etc/lilo.conf
   if [ $? -ne 0 ]; then
      echo "!!! Error #1011: Could not append initrd to lilo.conf."
      return 1
   fi
   
   # Install lilo
   chroot /mnt/gentoo lilo
   if [ $? -ne 0 ]; then
      echo "!!! Error #1012: Could not execute LILO."
      return 1
   fi   
fi

#############
# Any more? #
#############
}
