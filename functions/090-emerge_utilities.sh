emerge_utilities() {

   # This function is used to reduce code duplication for each utility.
   # It will emerge the specified utility and then add it the the default
   # runlevel.
   # Note: Remember to quote EMERGE_OPTIONS when passing to this function.
   emerge_sysutil() {
      OPTS=${1}
      PKG=${2}
      [ "${2}" == "" ] && PKG=${1} && OPTS=""
         
      chroot /mnt/gentoo emerge ${OPTS} ${PKG}
      if [ $? -ne 0 ]; then
         echo "!!! Error #0901: Could not emerge $2."
         return 1
      fi

      [ "${3}" == "" ] && RUNLEVEL="default"
      chroot /mnt/gentoo rc-update add ${PKG} ${RUNLEVEL}
      if [ $? -ne 0 ]; then
         echo "!!! Error #0902: Could not add ${PKG} init script."
         return 1
      fi
   }

source ${GLIS_CONFIG}

# Emerge system logger
[ "${SYSTEM_LOGGER}" == "" ] && SYSTEM_LOGGER="metalog"
emerge_sysutil "${EMERGE_OPTIONS}" ${SYSTEM_LOGGER} || return 1

# Emerge cron daemon
[ "${CRON_DAEMON}" == "" ] && CRON_DAEMON="vixie-cron"
emerge_sysutil "${EMERGE_OPTIONS}" ${CRON_DAEMON} || return 1

if [ "${CRON_DAEMON}" != "vixie-cron" ]; then
   chroot /mnt/gentoo crontab /etc/crontab
   if [ $? -ne 0 ]; then
      echo "!!! Error #0903: Failed to execute crontab."
      return 1
   fi   
fi

# Emerge utilities
if [ "${UTILITIES}" != "" ] ; then
   
   # Emerge rp-pppoe
   if [ $(echo "${UTILITIES}" | grep -c 'rp-pppoe') -eq 1 ]; then
      chroot /mnt/gentoo env USE="-X" emerge ${EMERGE_OPTIONS} rp-pppoe
      if [ $? -ne 0 ]; then
         echo "!!! Error #0901: Could not emerge rp-pppoe."
	 return 1
      fi
      UTILITIES="$(echo "${UTILITIES}" | sed "s/rp-pppoe//")"
   fi
	  
   # Emerge PCMCIA Card Services
   if [ $(echo "${UTILITIES}" | grep -c 'pcmcia-cs') -eq 1 ]; then
      chroot /mnt/gentoo emerge ${EMERGE_OPTIONS} pcmcia-cs
      if [ $? -ne 0 ]; then
         echo "!!! Error: #0901: Could not emerge pcmcia-cs."
         return 1
      fi
      
      chroot /mnt/gentoo rc-update add pcmcia boot
      if [ $? -ne 0 ]; then
         echo "!!! Error: #0902: Could not add pcmcia init script."
         return 1
      fi 	 
      UTILITIES="$(echo "${UTILITIES}" | sed "s/pcmcia-cs//")"
   fi
	  
   # Emerge other Utilities
   if [ "$(echo "${UTILITIES}" | sed "s/ //g")" != "" ]; then
      chroot /mnt/gentoo env USE="-X" emerge ${EMERGE_OPTIONS} ${UTILITIES}
      if [ $? -ne 0 ]; then
         echo "!!! Error #0904: Could not emerge one of: ${UTILITIES}"
	 return 1
      fi      
   fi
fi

# Emerge booloader
[ "${BOOT_LOADER}" == "" ] && BOOT_LOADER="grub"
chroot /mnt/gentoo emerge ${EMERGE_OPTIONS} ${BOOT_LOADER}
if [ $? -ne 0 ]; then
   echo "!!! Error #0901: Could not emerge ${BOOT_LOADER}."
   return 1
fi
}
