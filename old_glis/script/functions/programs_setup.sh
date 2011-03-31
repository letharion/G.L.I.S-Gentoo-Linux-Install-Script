#!/bin/bash

programs_setup() {
# Choose system logger
dialog --title "Gentoo Linux : Package Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose system logger. Move using [UP] [DOWN],[Enter] to Select" 15 80 4 metalog "(recommended)" sysklogd "" syslog-ng "" msyslog "" 2>/tmp/menuitem.tmp
menuitem=`cat /tmp/menuitem.tmp`
rm -f /tmp/menuitem.tmp
case $menuitem in
   metalog) export logger=metalog;;
   sysklogd) export logger=sysklogd;;
   syslog-ng) export logger=syslog-ng;;
   msyslog) export logger=msyslog;;
   *) return 1 ;; 
esac

# Choose cron daemon
dialog --title "Gentoo Linux : Package Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose cron daemon. Move using [UP] [DOWN],[Enter] to Select" 15 80 3 vcron "(recommended)" dcron "" fcron "" 2>/tmp/menuitem.tmp
menuitem=`cat /tmp/menuitem.tmp`
rm -f /tmp/menuitem.tmp
case $menuitem in
   vcron) export cron=vcron;;
   dcron) export cron=dcron;;
   fcron) export cron=fcron;;
   *) return 1 ;; 
esac

# Emerge extras
dialog --separate-output --title "Gentoo Linux : Package Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --checklist "Choose extra packages to emerge after kernel build.\nMove using [UP] [DOWN],[Space] to Select, and [Enter] to Continue" 15 100 7 rp-pppoe "A user-mode PPPoE client and server suite for Linux" off xfsprogs "Xfs filesystem utilities" off reiserfsprogs "Reiser filesystem utilities" off jfsutils "IBM's Journaling FileSystem (JFS) utilities" off lvm-user "User-land utilities for LVM (Logical Volume Manager) software" off pcmcia-cs "PCMCIA tools for Linux (MUST re-emerge after boot)" off 2> /tmp/checklist.tmp
export extras=`echo $(cat /tmp/checklist.tmp)`
rm -f /tmp/checklist.tmp
return 0
}