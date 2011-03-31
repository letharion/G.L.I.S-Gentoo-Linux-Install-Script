#!/bin/bash

run_install() {
# Begin Install
# Step 1 - Format and mount partitions
if [ $1 -le 1 ]; then
   format_partitions | dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 1 of 8: Formatting hard drive(s)..." 6 80
   [ "$(cat /tmp/glis/format-partitions-exitstatus.tmp)" != "0" ] && rm -f /tmp/glis/format-partitions-exitstatus.tmp && return 1
   mount_partitions
   if [ "$(cat /tmp/glis/format-partitions-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/format-partitions-exitstatus.tmp
      return 1
   else
      rm -f /tmp/glis/format-partitions-exitstatus.tmp
      rm -f /tmp/glis/format-partitions.log
   fi
fi

# Step 2 - Unpack tarball
if [ $1 -le 2 ]; then
   rm -f /mnt/gentoo/stage*.tar.bz2
   if [ ${tarballstyle} = "download" ] ; then   # download tarball
      download_tarball | dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --gauge "Step 2 of 8: Downloading stage ${installstage} tarball..." 6 80
      if [ "$(cat /tmp/glis/unpack-tarball-exitstatus.tmp)" != "0" ]; then
         rm -f /tmp/glis/unpack-tarball-exitstatus.tmp
         dialog --title "Gentoo Linux : Unpacking Tarball" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Error downloading tarball.  Please use CD with tarball or choose a different download mirror." 7 80
         return 2
      else
         rm -f /tmp/glis/unpack-tarball-exitstatus.tmp
         rm -f /tmp/glis/unpack-tarball.log
      fi
   else   # make a symbolic link to the tarball on the cd
      if [ -f /mnt/cdrom/stages/stage${installstage}-${arch}-${gentooversion}.tar.bz2 ]; then
         ln -s /mnt/cdrom/stages/stage${installstage}-${arch}-${gentooversion}.tar.bz2 /mnt/gentoo/stage${installstage}-${arch}-${gentooversion}.tar.bz2
      else
         dialog --title "Gentoo Linux : Unpacking Tarball" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Tarball not found on your cdrom.  Please use CD with tarball or download tarball." 7 80
         return 2
      fi
   fi
   unpack_tarball | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --gauge "Step 2 of 8: Unpacking stage ${installstage} tarball..." 6 80
   if [ "$(cat /tmp/glis/unpack-tarball-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/unpack-tarball-exitstatus.tmp
      return 2
   else
      rm -f /tmp/glis/unpack-tarball-exitstatus.tmp
      rm -f /tmp/glis/unpack-tarball.log
   fi
fi

# Step 3 - Prepare system
if [ $1 -le 3 ]; then
   prepare_system | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 3 of 8: Preparing system..." 6 80
fi

# Step 4 - Update portage tree (emerge sync)
if [ $1 -le 4 ]; then
   get_portage_tree | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 4 of 8: Updating the Portage tree..." 6 80
   if [ "$(cat /tmp/glis/emerge-sync-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/emerge-sync-exitstatus.tmp
      return 4
   else
      rm -f /tmp/glis/emerge-sync-exitstatus.tmp
      rm -f /tmp/glis/emerge-sync.log
   fi
fi

# Step 5 - Bootstrapping system
if [ $1 -le 5 ]; then
   bootstrap_system | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 5 of 8: Bootstrapping System..." 6 80
   if [ "$(cat /tmp/glis/emerge-bootstrap-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/emerge-bootstrap-exitstatus.tmp
      return 5
   else
      rm -f /tmp/glis/emerge-bootstrap-exitstatus.tmp
      rm -f /tmp/glis/emerge-bootstrap.log
   fi
fi

# Step 6 - Build system
if [ $1 -le 6 ]; then
   build_system | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 6 of 8: Building System..." 6 80
   if [ "$(cat /tmp/glis/emerge-system-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/emerge-system-exitstatus.tmp
      return 6
   else
      rm -f /tmp/glis/emerge-system-exitstatus.tmp
      rm -f /tmp/glis/emerge-system.log
   fi
fi

# Step 7 - Build Kernel
if [ $1 -le 7 ]; then
   if [ ${customkernel} = "true" ]; then   
      build_kernel
   else
      build_kernel | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 7 of 8: Building Kernel..." 6 80
   fi
   if [ "$(cat /tmp/glis/build-kernel-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/build-kernel-exitstatus.tmp
      return 7
   else
      rm -f /tmp/glis/build-kernel-exitstatus.tmp
      rm -f /tmp/glis/build-kernel.log
   fi
fi

# Step 8 - Implementing Configuration
if [ $1 -le 8 ]; then
   implement_config | dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --guage "Step 8 of 8: Implementing Configuration..." 6 80
   if [ "$(cat /tmp/glis/implement-config-exitstatus.tmp)" != "0" ]; then
      rm -f /tmp/glis/implement-config-exitstatus.tmp
      return 8
   else
      rm -f /tmp/glis/implement-config-exitstatus.tmp
      rm -f /tmp/glis/implement-config.log
   fi
fi
}