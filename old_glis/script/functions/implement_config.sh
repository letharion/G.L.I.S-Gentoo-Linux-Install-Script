#!/bin/bash

implement_config() {
echo 1
# Emerge system logger
chroot_env_set "emerge ${logger}"
chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
echo $? > /tmp/glis/implement-config-exitstatus.tmp
[ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching ${logger}!" >> /tmp/glis/implement-config.log && return 1
echo 20

# Emerge cron daemon
chroot_env_set "emerge ${cron}"
chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
echo $? > /tmp/glis/implement-config-exitstatus.tmp
[ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching ${cron}!" >> /tmp/glis/implement-config.log && return 1
echo 40

# Emerge extras
if [ "${extras}" != "" ] ; then
   chroot_env_set "USE="-X" emerge ${extras}"
   chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
   echo $? > /tmp/glis/implement-config-exitstatus.tmp
   [ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching one of the following: ${extras}!" >> /tmp/glis/implement-config.log && return 1
fi
echo 60

# Emerge bootloader
chroot_env_set "emerge ${bootloader}"
chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
echo $? > /tmp/glis/implement-config-exitstatus.tmp
[ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching grub!" >> /tmp/glis/implement-config.log && return 1
echo 80

# Setup runlevels
if [ "${cron}" != "vcron" ]; then
   chroot_env_set "rc-update add ${logger} default" "rc-update add ${cron} default" "rc-update add net.eth0 default" "crontab /etc/crontab"
else
   chroot_env_set "rc-update add ${logger} default" "rc-update add ${cron} default" "rc-update add net.eth0 default"
fi
chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
echo 85

# Set time zone 
ln -sf ${usertimezone} /mnt/gentoo/etc/localtime 

# Set password
rm -f /mnt/gentoo/etc/shadow
cp /etc/shadow /mnt/gentoo/etc/shadow

# Set the Hostname
echo ${hostname} > /mnt/gentoo/etc/hostname
echo ${domain} > /mnt/gentoo/etc/dnsdomainname
echo -e "${ip}\t${hostname}.${domain}\t${hostname}" >> /mnt/gentoo/etc/hosts
echo 90

if [ "${bootloader}" = "grub" ]; then
   # Config grub
   rm -f /mnt/gentoo/boot/grub/menu.lst
   echo -e "default 0\ntimeout 30\nsplashimage=(${grubboot})/boot/grub/splash.xpm.gz\n\ntitle=Gentoo Linux\nroot (${grubboot})\nkernel (${grubboot})/boot/vmlinuz root=${rootpart} vga=791" > /mnt/gentoo/boot/grub/grub.conf
   [ -f /mnt/gentoo/boot/grub/grub.conf ] && ln -s /boot/grub/grub.conf /mnt/gentoo/boot/grub/menu.lst
   [ ! -f /mnt/gentoo/boot/grub/grub.conf ] && echo "*** Error: no grub.conf found!" >> /tmp/glis/implement-config.log && return 1

   # Add initrd to grub.conf?
   [ ${customkernel} != "true" ] && echo -e "initrd (${grubboot})/boot/initrd" >> /mnt/gentoo/boot/grub/grub.conf
   
   # Windows partitions?
   ls --color=none /dev/discs/disc*/part* > /tmp/glis/partitionlist.tmp
   i=0
   while read partition ; do
      partitiontype=`sfdisk --id $(echo ${partition} | sed "s/\(\/dev\/discs\/disc.*\)\/part.*/\1\/disc/") $(echo ${partition} | sed "s/\/dev\/discs\/disc.*\/part\(.*\)/\1/")`
      if [ "${partitiontype}" == "6" ] || [ "${partitiontype}" == "7" ] || [ "${partitiontype}" == "b" ] || [ "${partitiontype}" == "c" ] || [ "${partitiontype}" == "e" ] || [ "${partitiontype}" == "f" ]; then
         i=`expr $i + 1`
         grubstyle="hd$(echo ${partition} | sed "s/\/dev\/discs\/disc\(.*\)\/part.*/\1/"),$(expr $(echo ${partition} | sed "s/\/dev\/discs\/disc.*\/part\(.*\)/\1/") - 1)"
         echo -e "\n\n# non linux partition\ntitle=Windows${i}\nroot (${grubstyle})\nchainloader (${grubstyle})+1" >>/mnt/gentoo/boot/grub/grub.conf
      fi
   done < /tmp/glis/partitionlist.tmp
   rm /tmp/glis/partitionlist.tmp
   
   # Install grub
   chroot_env_set "grub --no-floppy --batch <<EOT\nroot (${grubboot})\nsetup (${grubinstalldrive}${grubinstallpart})\nquit\nEOT"
   chroot /mnt/gentoo >>/tmp/glis/implement-config.log 2>&1
   echo $? > /tmp/glis/implement-config-exitstatus.tmp
   [ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error setting up grub!" >> /tmp/glis/implement-config.log && return 1
else
   # Config lilo
   echo -e "boot=${liloinstall}\nmap=/boot/map\ninstall=/boot/boot.b\nprompt\ntimeout=50\nlba32\ndefault=linux\n\nimage=/boot/vmlinuz\n\tlabel=linux\n\tread-only\n\troot=${rootpart}" > /mnt/gentoo/etc/lilo.conf

   # Add initrd to lilo.conf?
   [ ${customkernel} != "true" ] && echo -e "\tinitrd=/boot/initrd" >> /mnt/gentoo/etc/lilo.conf
   
   # Windows partitions?
   ls --color=none /dev/discs/disc*/part* > /tmp/glis/partitionlist.tmp
   i=0
   while read partition ; do
      partitiontype=`sfdisk --id $(echo ${partition} | sed "s/\(\/dev\/discs\/disc.*\)\/part.*/\1\/disc/") $(echo ${partition} | sed "s/\/dev\/discs\/disc.*\/part\(.*\)/\1/")`
      if [ "${partitiontype}" == "6" ] || [ "${partitiontype}" == "7" ] || [ "${partitiontype}" == "b" ] || [ "${partitiontype}" == "c" ] || [ "${partitiontype}" == "e" ] || [ "${partitiontype}" == "f" ]; then
         i=`expr $i + 1`
         echo -e "\n\n# non linux partition\nother=${partition}\n\tlabel=Windows${i}" >>/mnt/gentoo/etc/lilo.conf
      fi
   done < /tmp/glis/partitionlist.tmp
   rm /tmp/glis/partitionlist.tmp

   # Install lilo
   chroot_env_set "lilo"
   chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
   echo $? > /tmp/glis/implement-config-exitstatus.tmp
   [ $(cat /tmp/glis/implement-config-exitstatus.tmp) -ne 0 ] && echo "*** Error setting up lilo!" >> /tmp/glis/implement-config.log && return 1
fi
echo 95

# Edit config files
chroot_env_set "echo \"-5\" | etc-update"
chroot /mnt/gentoo >> /tmp/glis/implement-config.log 2>&1
etc_config "make.conf"
etc_config "rc.conf"
etc_config "net"
etc_config "profile"
etc_config "fstab"
echo 100
}