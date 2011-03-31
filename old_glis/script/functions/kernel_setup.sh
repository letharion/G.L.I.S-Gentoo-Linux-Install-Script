#!/bin/bash

kernel_setup() {
export customkernel=""
# Detect config file
if [ -s /mnt/gentoo/boot/config ] || [ -s /mnt/gentoo/boot/.config ] ; then
   dialog --title "Gentoo Linux : Kernel Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "\nAn existing kernel config file was found in '/mnt/gentoo/boot'. \n\nDo you want to use it?" 9 80 
   sel=$? 
   case $sel in 
      0) export customkernel=true;; 
      1) rm -f /mnt/gentoo/boot/config; rm -f /mnt/gentoo/boot/.config;;
      255) return 1;; 
   esac
fi

# Prompt to choose kernel style
if [ -z ${customkernel} ] ; then
   dialog --title "Gentoo Linux : Kernel Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "\nBuilding your own custom kernel requires knowledge of your computer's hardware. \n\nDo you want to make your own custom kernel?" 9 80 
   sel=$? 
   case $sel in 
      0) export customkernel=true;; 
      1) export customkernel=false; export kernelsource=gentoo-sources;; 
      255) return 1;; 
   esac
fi

# Choose a kernel source
if [ ${customkernel} = "true" ] ; then
   dialog --title "Gentoo Linux : Kernel Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose kernel source. Move using [UP] [DOWN],[Enter] to Select" 20 120 14 gentoo-sources "(recommended)" aa-sources "Full sources for Andrea Arcangeli's Linux kernel" ac-sources "Full sources for Alan Cox's Linux kernel" ck-sources "Full sources for the Stock Linux kernel Con Kolivas's high performance patchset" development-sources "Full sources for the Development Branch of the Linux kernel" gaming-sources "Full sources for the Gentoo gaming-optimized kernel" gs-sources "This kernel stays up to date with current goodies" mm-sources "Full sources for the development linux kernel with Andrew Morton's patchset" openmosix-sources "Full sources for the Gentoo openMosix Linux kernel" pfeifer-sources "Full sources for the experimental Gentoo Kernel. Patches from here go to gentoo-sources" selinux-sources "LSM patched kernel with SELinux archive" vanilla-sources "Full sources for the Linux kernel" win4lin-sources "Full sources for the linux kernel with win4lin support" xfs-sources "Full sources for the XFS Specialized Gentoo Linux kernel" 2>/tmp/menuitem.$$
   menuitem=`cat /tmp/menuitem.$$`
   rm -f /tmp/menuitem.$$
   case $menuitem in
      gentoo-sources) export kernelsource=gentoo-sources;;
      aa-sources) export kernelsource=aa-sources;;
      ac-sources) export kernelsource=ac-sources;;
      ck-sources) export kernelsource=ck-sources;;
      development-sources) export kernelsource=development-sources;;
      gaming-sources) export kernelsource=gaming-sources;;
      gs-sources) export kernelsource=gs-sources;;
      mm-sources) export kernelsource=mm-sources;;
      openmosix-sources) export kernelsource=openmosix-sources;;
      pfeifer-sources) export kernelsource=pfeifer-sources;;
      selinux-sources) export kernelsource=selinux-sources;;
      vanilla-sources) export kernelsource=vanilla-sources;;
      win4lin-sources) export kernelsource=win4lin-sources;;
      xfs-sources) export kernelsource=xfs-sources;;
      *) return 1 ;; 
   esac
fi
return 0
}