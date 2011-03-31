#!/bin/bash
#***--glis--******************************************************************
#
#     Gentoo Linux Install Script (GLIS) - version 0.7
#
#        Copyright 2003 Nathaniel McCallum. 
#
#    For all queries about this code, please contact the current author, 
#    Nathaniel McCallum <npmccallum@users.sourceforge.net> and not 
#    Gentoo Linux.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This software is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#*****************************************************************************
echo -e "\nGLIS v0.7 - Please wait.  Starting installation...\n"

# create a temp directory to extract to.
rm -rf /tmp/glis
mkdir /tmp/glis

skip=`awk '/^__ARCHIVE_FOLLOWS__/ { print NR + 1; exit 0; }' $0`

# Take the TGZ portion of this file and pipe it to tar.
tail +$skip $0 | tar xz -C /tmp/glis/

# Execute the installation script
previousdir=`pwd`
cd /tmp/glis
bash script/glis.sh
installstatus=$?

# Delete the temp files
cd $previousdir
rm -rf /tmp/glis
rm -rf /mnt/gentoo/tmp/glis
rm -f /mnt/gentoo/root/.bashrc
rm -f /mnt/gentoo/stage*.tar.bz2

# Error Check
[ ${installstatus} -ne 0 ] && echo "Quitting..." && exit 1
rebootstatus=1
while [ ${rebootstatus} != "0" ]; do
   dialog --no-cancel --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Installation has completed sucessfully.  Please choose from the following options:" 11 80 3 Reboot "Reboot into the new system." Bootdisk "Make bootdisks" Quit "Quit to a shell" 2>/tmp/exitchoice.tmp
   exitchoice=`cat /tmp/exitchoice.tmp`
   rm -f /tmp/exitchoice.tmp
   [ "${exitchoice}" = "Quit" ] && echo "Quitting to shell..." && exit 0
   [ "${exitchoice}" = "Reboot" ] && rebootstatus=0
   if [ "${exitchoice}" = "Bootdisk" ]; then
      dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Please enter a disk." 5 80
      if [ $? -eq 0 ]; then
         if [ -f /mnt/gentoo/boot/grub/grub.conf ]; then
            cat /mnt/gentoo/usr/share/grub/i386-pc/stage1 /mnt/gentoo/usr/share/grub/i386-pc/stage2 > /dev/fd0
            [ $? -eq 0 ] && dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Boot disk created." 3 80
            [ $? -ne 0 ] && dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "An error occured while creating bootdisk.  Boot disk NOT created!" 5 80
        else
            if [ -f /mnt/gentoo/boot/vmlinuz ]; then
               if [ $(expr $(ls -l --color=none /mnt/gentoo/boot/vmlinuz | cut -c 35-47) / 10000) -lt 135 ]; then         
                  dd if=/mnt/gentoo/boot/vmlinuz of=/dev/fd0
                  [ $? -eq 0 ] && dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Boot disk created." 3 80
               else
                  dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "The kernel is too big to fit on the disk.  Boot disk NOT created!" 5 80
               fi
            else
               dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "The kernel was not found.  Boot disk NOT created!" 5 80
            fi
         fi
      fi
   fi
done

# Done!
dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Rebooting..." 3 80
cd /
umount /mnt/gentoo/* >> /dev/null 2>&1
umount /mnt/gentoo >> /dev/null 2>&1
clear
reboot
exit

__ARCHIVE_FOLLOWS__
