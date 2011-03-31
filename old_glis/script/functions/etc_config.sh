#!/bin/bash

# This function does all the configuration file manipulation
etc_config() {
if [ "$1" = "net" ]; then
   # Configure /etc/conf.d/net
   case ${nettype} in
      DHCP)
         write_config "iface_eth0=\"192" "#iface_eth0=\"192.168.0.2 broadcast 192.168.0.255 netmask 255.255.255.0\"" /mnt/gentoo/etc/conf.d/net ".168."
         write_config "iface_eth0=\"d" "iface_${nic}=\"dhcp\"" /mnt/gentoo/etc/conf.d/net "hcp"
         write_config "dhcpcd_eth0" "dhcpcd_${nic}=\"-t 10\"" /mnt/gentoo/etc/conf.d/net "=";;
      Static)
         write_config "iface_eth0=\"192" "iface_eth0=\"${ip} broadcast ${broadcast} netmask ${netmask}\"" /mnt/gentoo/etc/conf.d/net ".168."
         write_config "gateway" "gateway=\"${nic}/${gateway}\"" /mnt/gentoo/etc/conf.d/net "=";;
   esac
fi

if [ "$1" = "fstab" ]; then
   if [ $(grep -c "/ROOT" /mnt/gentoo/etc/fstab) -gt 0 ]; then
      # Configure /etc/fstab
      [ "${roottype}" != "reiserfs" ] && write_config "/dev/RO" "${rootpart}\t/\t\t${roottype}\t\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "OT"
      [ "${roottype}" == "reiserfs" ] && write_config "/dev/RO" "${rootpart}\t/\t\t${roottype}\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "OT"
      if [ "${swappart}" != "" ]; then
         write_config "/dev/SW" "${swappart}\tnone\t\tswap\t\tsw\t\t\t0 0" /mnt/gentoo/etc/fstab "AP"
      else
         cat /mnt/gentoo/etc/fstab | grep -v "/dev/SWAP" > /tmp/glis/fstab.tmp
         mv -f /tmp/glis/fstab.tmp /mnt/gentoo/etc/fstab
      fi
      if [ "${bootpart}" != "" ]; then
         [ "${boottype}" != "reiserfs" ] && write_config "/dev/BO" "${bootpart}\t/boot\t\t${boottype}\t\tnoauto,noatime\t\t1 1" /mnt/gentoo/etc/fstab "OT"
         [ "${boottype}" == "reiserfs" ] && write_config "/dev/BO" "${bootpart}\t/boot\t\t${boottype}\tnoauto,noatime,notail\t1 1" /mnt/gentoo/etc/fstab "OT"
      else
         cat /mnt/gentoo/etc/fstab | grep -v "/dev/BOOT" > /tmp/glis/fstab.tmp
         mv -f /tmp/glis/fstab.tmp /mnt/gentoo/etc/fstab
      fi
      [ "${homepart}" != "" ] && [ "${boottype}" != "reiserfs" ] && write_config "/dev/HO" "${homepart}\t/home\t\t${hometype}\t\tnoatime\t\t0 0" /mnt/gentoo/etc/fstab "ME"
      [ "${homepart}" != "" ] && [ "${boottype}" == "reiserfs" ] && write_config "/dev/HO" "${homepart}\t/home\t\t${hometype}\tnoatime\t\t0 0" /mnt/gentoo/etc/fstab "ME"
      [ "${rootuserpart}" != "" ] && [ "${rootusertype}" != "reiserfs" ] && write_config "/dev/ROOTUS" "${rootuserpart}\t/root\t\t${rootusertype}\t\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "ER"
      [ "${rootuserpart}" != "" ] && [ "${rootusertype}" == "reiserfs" ] && write_config "/dev/ROOTUS" "${rootuserpart}\t/root\t\t${rootusertype}\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "ER"
      [ "${tmppart}" != "" ] && [ "${tmptype}" != "reiserfs" ] && write_config "/dev/T" "${tmppart}\t/tmp\t\t${tmptype}\t\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "MP"
      [ "${tmppart}" != "" ] && [ "${tmptype}" == "reiserfs" ] && write_config "/dev/T" "${tmppart}\t/tmp\t\t${tmptype}\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "MP"
      [ "${usrpart}" != "" ] && [ "${tmptype}" != "reiserfs" ] && write_config "/dev/U" "${usrpart}\t/usr\t\t${usrtype}\t\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "SR"
      [ "${usrpart}" != "" ] && [ "${tmptype}" == "reiserfs" ] && write_config "/dev/U" "${usrpart}\t/usr\t\t${usrtype}\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "SR"
      [ "${varpart}" != "" ] && [ "${tmptype}" != "reiserfs" ] && write_config "/dev/V" "${varpart}\t/var\t\t${vartype}\t\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "AR"
      [ "${varpart}" != "" ] && [ "${tmptype}" == "reiserfs" ] && write_config "/dev/V" "${varpart}\t/var\t\t${vartype}\tnoatime\t\t\t0 0" /mnt/gentoo/etc/fstab "AR"
   fi
fi

if [ "$1" = "rc.conf" ]; then
   # Configure /etc/rc.conf
   write_config "CLOCK" "CLOCK=\"${clock}\"" /mnt/gentoo/etc/rc.conf "="
fi

if [ "$1" = "make.conf" ]; then
   # Configure /etc/make.conf
   write_config "USE" "USE=\"${usevar}\"" /mnt/gentoo/etc/make.conf "="
   write_config "CHOST" "CHOST=\"${chostvar}\"" /mnt/gentoo/etc/make.conf "="
   write_config "CFLAGS" "CFLAGS=\"${cflagsvar}\"" /mnt/gentoo/etc/make.conf "="
   write_config "CXXFLAGS" "CXXFLAGS=\"${cxxflagsvar}\"" /mnt/gentoo/etc/make.conf "="
   [ "${gentoomirrorsvar}" != "" ] && write_config "GENTOO_MIRRORS" "GENTOO_MIRRORS=\"${gentoomirrorsvar}\"" /mnt/gentoo/etc/make.conf "="
fi

if [ "$1" = "profile" ]; then
   # Configure /etc/profile
   [ "${http_proxy}" != "" ] && write_config "export http_proxy" "export http_proxy=\"${http_proxy}\"" /mnt/gentoo/etc/profile "="
   [ "${ftp_proxy}" != "" ] && write_config "export ftp_proxy" "export ftp_proxy=\"${ftp_proxy}\"" /mnt/gentoo/etc/profile "="
   [ "${RSYNC_PROXY}" != "" ] && write_config "export RSYNC_PROXY" "export RSYNC_PROXY=\"${RSYNC_PROXY}\"" /mnt/gentoo/etc/profile "="
fi
return 0
}