#!/bin/bash

# Function to setup partitions
partition_setup () {
partition_drive() {
# Partition hard drive
partcount=0
while [ ${partcount} -eq 0 ]; do
   cfdisk ${1}/disc
   partcount=`ls --color=none ${1}/part* | grep -c ${1}/part`
   [ ${partcount} -eq 0 ] && dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "No partitions detected.  Would you like to create a partition?" 7 80
   [ ${?} -ne 0 ] && partcount=1
done
return 0
}

choose_drive() {
ls --color=none -d /dev/discs/disc* > /tmp/glis/drivelist.tmp
drivecount=`grep -c /dev/discs/disc /tmp/glis/drivelist.tmp`
if [ ${drivecount} -eq 0 ]; then
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "No drives detected.  You must have a drive installed!" 7 80
   return 2
fi
listheight=`expr ${drivecount} + 1`
[ ${listheight} -gt 11 ] && listheight=11
start="dialog --title \"Gentoo Linux : Partition Setup\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --menu \"Choose a drive to partition.\" `expr ${listheight} + 8` 40 ${listheight} "
middle=`cat /tmp/glis/drivelist.tmp | sed "s/\(\/dev\/discs\/disc.*\)/\1 \"\"/"`
end=" Finished \"\" 2> /tmp/glis/menuitem.tmp"
echo ${start}${middle}${end} | sh
if [ $? -ne 0 ]; then
   rm -f /tmp/glis/menuitem.tmp
   rm -f /tmp/glis/drivelist.tmp
   return 2
else
   drivetopartition=`cat /tmp/glis/menuitem.tmp`
   rm -f /tmp/glis/menuitem.tmp
   rm -f /tmp/glis/drivelist.tmp
fi
testchoice=`echo ${drivetopartition} | sed -n "s/\/dev\/discs\/disc.*/valid/gIp"`
if [ "${drivetopartition}" = "Finished" ] || [ "${testchoice}" = "" ]; then
   partcount=`ls --color=none /dev/discs/disc*/part* | grep -c /dev/discs/`
   [ ${partcount} -eq 0 ] && dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "No partitions detected.  You must have partitions!" 7 80 && return 1
   [ ${partcount} -ne 0 ] && return 0
fi
partition_drive ${drivetopartition}
return 1
}

assign_partition() {
partitiontype=`sfdisk --id $(echo ${1} | sed "s/\(\/dev\/discs\/disc.*\)\/part.*/\1\/disc/") $(echo ${1} | sed "s/\/dev\/discs\/disc.*\/part\(.*\)/\1/")`

# If partition is a swap type, prompt to mount it
if [ ${partitiontype} -eq 82 ]; then
   swapstatus=""
   [ -s /tmp/glis/partitionconfig.var ] && swapstatus="$(grep swappart /tmp/glis/partitionconfig.var | sed "s/swappart=\"\(.*\)\"/\1/")"
   if [ "${swapstatus}" = "" ]; then
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "Would you like to use \"${1}\" as your swap partition?" 6 80
      [ ${?} -ne 0 ] && return 0
   else
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "Swap partition already setup. Would you like to use \"${1}\" as your swap partition instead of \"${swapstatus}\"?" 6 80
      [ ${?} -ne 0 ] && return 0
   fi
   write_config "swappart" "swappart=\"$1\"" /tmp/glis/partitionconfig.var "="
   write_config "swaptype" "swaptype=\"swap\"" /tmp/glis/partitionconfig.var "="

# If partition is a non-swap partition then...
elif [ ${partitiontype} -eq 83 ]; then

   # Remove old mountpoint if it exists
   oldmountpoint=`grep ${1} /tmp/glis/partitionconfig.var | awk -F part= '{ print $1 }'`
   [ "${oldmountpoint}" != "" ] && cat /tmp/glis/partitionconfig.var | grep -v ${oldmountpoint} > /tmp/glis/partitionconfig.tmp && mv -f /tmp/glis/partitionconfig.tmp /tmp/glis/partitionconfig.var

   # Detect which mountpoints have not been used
   echo -e "root\nboot\nhome\nrootuser\ntmp\nusr\nvar" > /tmp/glis/mountpoint.tmp
   cat /tmp/glis/partitionconfig.var | sed -n "s/\(.*\)part=.*/\1/gIp" >> /tmp/glis/mountpoint.tmp
   
   rm -f /tmp/glis/dialogmountpoint.tmp
   while read line ; do
      if [ "${line}" = "root" ]; then
         echo "/ \"\"" >> /tmp/glis/dialogmountpoint.tmp
      elif [ "${line}" = "rootuser" ]; then
         echo "/root \"\"" >> /tmp/glis/dialogmountpoint.tmp
      elif [ "${line}" = "swap" ]; then
         echo "" >> /tmp/glis/dialogmountpoint.tmp
      else
         echo ${line} | sed "s/\(.*\)/\/\1 \"\"/" >> /tmp/glis/dialogmountpoint.tmp
      fi
   done < /tmp/glis/mountpoint.tmp
   rm -f /tmp/glis/mountpoint.tmp
   cat /tmp/glis/dialogmountpoint.tmp | sort | uniq -u > /tmp/glis/dialogmountpoint.tmp 
   listheight=`grep -c / /tmp/glis/dialogmountpoint.tmp`
   [ "${listheight}" = "" ] && listheight=0
   listheight=`expr ${listheight} + 1`
   [ ${listheight} -gt 8 ] && listheight=8

   # Choose from the available mount points
   start="dialog --title \"Gentoo Linux : Partition Setup\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --menu \"Where would you like to mount \\\"${1}\\\"?\" `expr ${listheight} + 8` 80 ${listheight} "
   middle=`cat /tmp/glis/dialogmountpoint.tmp`
   end=' none "" 2> /tmp/glis/menuitem.tmp'
   echo ${start}${middle}${end} | sh
   [ $? -ne 0 ] && return 1
   mountpointchoice=`cat /tmp/glis/menuitem.tmp`
   rm -f /tmp/glis/menuitem.tmp
   rm -f /tmp/glis/dialogmountpoint.tmp

   # Create new mountpoint variable
   case ${mountpointchoice} in
      /) mountpoint="root" ;;
      /boot) mountpoint="boot" ;;
      /home) mountpoint="home" ;;
      /root) mountpoint="rootuser" ;;
      /tmp) mountpoint="tmp" ;;
      /usr) mountpoint="usr" ;;
      /var) mountpoint="var" ;;
      none) return 0 ;;
   esac

   # And the filesystem type
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Which filesystem will you use for \"${1}\"?" 13 80 5 ext2 "" ext3 "" reiserfs "" jfs "" xfs "" 2> /tmp/menuitem.tmp
   [ $? -ne 0 ] && return 1
   fstype=`cat /tmp/menuitem.tmp`
   rm -f /tmp/menuitem.tmp

   write_config "${mountpoint}part" "${mountpoint}part=\"${1}\"" /tmp/glis/partitionconfig.var "="
   write_config "${mountpoint}type" "${mountpoint}type=\"${fstype}\"" /tmp/glis/partitionconfig.var "="
fi
}

choose_partition() {
ls --color=none /dev/discs/disc*/part* > /tmp/glis/partitionlist.tmp
partcount=`grep -c /dev/discs/disc /tmp/glis/partitionlist.tmp`
sfdiskpartcount=`sfdisk -l 2>&1 | grep /part | grep -vc Empty`
[ "${sfdiskpartcount}" != "${partcount}" ] && return 2
nonlinuxpartcount=0
for (( i = 1 ; i <= ${partcount} ; i++ )); do
   partition=`head -${i} /tmp/glis/partitionlist.tmp | tail -1`
   partitiontype=`sfdisk --id $(echo ${partition} | sed "s/\(\/dev\/discs\/disc.*\)\/part.*/\1\/disc/") $(echo ${partition} | sed "s/\/dev\/discs\/disc.*\/part\(.*\)/\1/")`
   if [ "${partitiontype}" = "82" ] || [ "${partitiontype}" = "83" ]; then
      partitionmountpoint=`grep ${partition} /tmp/glis/partitionconfig.var | awk -F part= '{ print $1 }'`
      if [ "${partitionmountpoint}" != "" ]; then
         partitionfstype=`grep ${partitionmountpoint}type /tmp/glis/partitionconfig.var | awk -F = '{ print $2 }'`
         case ${partitionmountpoint} in
            root) partitionmountpoint="/" ;;
            boot) partitionmountpoint="/boot" ;;
            home) partitionmountpoint="/home" ;;
            rootuser) partitionmountpoint="/root" ;;
            tmp) partitionmountpoint="/tmp" ;;
            usr) partitionmountpoint="/usr" ;;
            var) partitionmountpoint="/var" ;;
         esac
      else
         partitionmountpoint="Not yet mounted"
         partitionfstype="none"
      fi
      [ $i -eq 1 ] && rm -f /tmp/glis/dialogpartlist.tmp
      echo -e "$partition=\"Mountpoint: ${partitionmountpoint} Type: ${partitionfstype}\"" >> /tmp/glis/dialogpartlist.tmp
   else
      nonlinuxpartcount=`expr ${nonlinuxpartcount} + 1`
   fi
done
listheight=`expr ${partcount} + 2 - ${nonlinuxpartcount}`
[ ${listheight} -gt 11 ] && listheight=11
start="dialog --title \"Gentoo Linux : Partition Setup\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --menu \"Choose a partition to setup.\" `expr ${listheight} + 8` 80 ${listheight} "
middle=`cat /tmp/glis/dialogpartlist.tmp | awk -F = '{ print $1" "$2 }'`
end=' Repartition "Choose this to go back and repartition a drive" Finished "Choose this to complete partition setup" 2> /tmp/glis/menuitem.tmp'
echo ${start}${middle}${end} | sh
if [ $? -ne 0 ]; then
   rm -f /tmp/glis/menuitem.tmp
   rm -f /tmp/glis/partitionlist.tmp
   rm -f /tmp/glis/dialogpartlist.tmp
   return 4
else
   partitiontosetup=`cat /tmp/glis/menuitem.tmp`
   rm -f /tmp/glis/menuitem.tmp
   rm -f /tmp/glis/partitionlist.tmp
   rm -f /tmp/glis/dialogpartlist.tmp
fi
[ "${partitiontosetup}" = "Repartition" ] && return 3
testchoice=`echo ${partitiontosetup} | sed -n "s/\/dev\/discs\/disc.*\/part.*/valid/gIp"`
if [ "${partitiontosetup}" = "Finished" ] || [ "${testchoice}" = "" ]; then
   rootcheck=`grep -c rootpart /tmp/glis/partitionconfig.var`
   [ ${rootcheck} -eq 0 ] && dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "No / partition found.  Please make one." 6 80 && return 1
   bootcheck=`grep -c bootpart /tmp/glis/partitionconfig.var`
   [ ${bootcheck} -eq 0 ] && dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "No /boot partition found.  Do you want to go back and make one?" 6 80
   [ $? -ne 1 ] && return 1
   swapcheck=`grep -c swappart /tmp/glis/partitionconfig.var`
   [ ${swapcheck} -eq 0 ] && dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "No swap partition found.  Do you want to go back and make one?" 6 80
   [ $? -ne 1 ] && return 1
   return 0
fi
assign_partition ${partitiontosetup}
return 1
}

# Unmount all drives
swapoff $(cat /proc/swaps | grep -v Filename | awk -F " " '{ print $1 }') >/dev/null 2>&1
exitstatus=$?
if [ ${exitstatus} -ne 0 ] && [ ${exitstatus} -ne 2 ]; then
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Error unmounting swap partition." 6 80
   return 1
fi
umount `cat /proc/mounts | grep "/mnt/gentoo" | awk -F " " '{ print $2 }' | sort -r` >/dev/null 2>&1
exitstatus=$?
if [ ${exitstatus} -ne 0 ] && [ ${exitstatus} -ne 2 ]; then
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Error unmounting partitions." 6 80
   return 1
fi
umount `cat /proc/mounts | grep "/dev/" | grep -v tmpfs | grep -v cdrom | grep -v "/dev/fd" | grep -v cloop | awk -F " " '{ print $2 }' | sort -r` >/dev/null 2>&1
exitstatus=$?
if [ ${exitstatus} -ne 0 ] && [ ${exitstatus} -ne 2 ]; then
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Error unmounting partitions." 6 80
   return 1
fi

# Get variables for default partitioning
swapsize=`expr $(cat /proc/meminfo | grep MemTotal | sed "s/.* \(.*\) kB/\1/") / 1000 \* 2`
[ ${swapsize} -gt 512 ] && swapsize=512
rootsize=`echo -e ",64\n,${swapsize}\n,\n;\n" | sfdisk -uM -D -n /dev/discs/disc0/disc 2>/dev/null | tail +$(echo -e ",64\n,${swapsize}\n,\n;\n" | sfdisk -uM -D -n /dev/discs/disc0/disc 2>/dev/null | awk '/^New situation:/ { print NR + 1; exit 0; }') | grep /dev/discs/disc0/part3 | cut -c 41-46`
rootsizetype="MB"
[ $(expr ${rootsize} / 1000) -ge 1 ] && rootsizetype="GB" && rootsize="$(expr ${rootsize} / 1000).$(expr ${rootsize} % 1000 / 100)"

# Prompt for partition style
dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "The default disk partitioning is as follows:\n\n/dev/discs/disc0/part1 - mount: /boot type: ext3 size: 64MB\n/dev/discs/disc0/part2 - mount: swap  type: swap size: ${swapsize}MB\n/dev/discs/disc0/part3 - mount: /     type: ext3 size: `echo ${rootsize}`${rootsizetype}\n\nIf you choose the default partitioning, all current partitions on your first drive will be deleted and Grub will be installed to the Master Boot Record.\n\nDo you want to use default disk partitioning?" 16 80
[ $? -eq 0 ] && partitionstyle="default"
[ $? -ne 0 ] && partitionstyle="custom"

if [ ${partitionstyle} = "custom" ]; then
   # These loops allow us to go back and repartition at any time
   export validpartconfig="false"
   while [ ${validpartconfig} = "false" ]; do
      export dopartitionsetup="true"
      while [ "${dopartitionsetup}" = "true" ]; do
         needdriveconfig="true"
         if [ "${needdriveconfig}" = "true" ]; then
         
            # This starts the partition configuration file
            echo "# This file holds the temporary configuration for partitions" > /tmp/glis/partitionconfig.var

            # Setup partitions
            exitstatus=1
            while [ ${exitstatus} -ne 0 ]; do
               choose_drive; exitstatus=$?
               [ ${exitstatus} -eq 2 ] && return 1
            done
         fi

         # Setup partition mountpoints and filesystem types
         exitstatus=1
         while [ ${exitstatus} -ne 0 ]; do
            choose_partition; exitstatus=$?
            [ ${exitstatus} -eq 0 ] && dopartitionsetup="false"
            if [ ${exitstatus} -eq 2 ]; then
               dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Kernel is still using the old partition table.  Please reboot." 6 80
               return 1
            fi
            [ ${exitstatus} -eq 3 ] && dopartitionsetup="true" && exitstatus=0
            [ ${exitstatus} -eq 4 ] && return 1
         done
      done

      # Load partition variables
      rootpart=""; swappart=""; bootpart=""; homepart=""; rootuserpart=""; tmppart=""; usrpart=""; varpart=""
      source /tmp/glis/partitionconfig.var
   
      # Choose bootloader
      dialog --no-cancel --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose which bootloader to use:" 11 80 2 grub "(recommended)" lilo "" 2>/tmp/glis/menuitem.tmp
      [ $? -ne 0 ] && rm -f /tmp/glis/menuitem.tmp && return 1
      export bootloader=`cat /tmp/glis/menuitem.tmp`
      rm -f /tmp/glis/menuitem.tmp
   
      # Choose where to install the bootloader
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "Install ${bootloader} to your Master Boot Record? (If you choose \"No\", it will be installed to your /boot partition.  If you do not have a /boot partition, it will be installed to your / partition.)" 9 80
      sel=${?}
      if [ ${bootloader} = "grub" ]; then
         case ${sel} in
            0) export grubinstalldrive="hd0"; export grubinstallpart="";;
            1) if [ "${bootpart}" = "" ]; then
                  export grubinstalldrive="$(echo ${rootpart} | sed 's/\/dev\/discs\/disc\(.*\)\/part.*/hd\1/')"
                  export grubinstallpart="$(echo ${rootpart} | sed 's/\/dev\/discs\/disc.*\/part\(.*\)/,\1/')"
               else
                  export grubinstalldrive="$(echo ${bootpart} | sed 's/\/dev\/discs\/disc\(.*\)\/part.*/hd\1/')"
		          export grubinstallpart="$(echo ${bootpart} | sed 's/\/dev\/discs\/disc.*\/part\(.*\)/,\1/')"
		       fi;;
            *) return 1;;
         esac
      
         # Choose boot drive and partition for grub
         if [ "${bootpart}" = "" ]; then
            grubbootdrive="$(echo ${rootpart} | sed 's/\/dev\/discs\/disc\(.*\)\/part.*/\1/')"
            grubbootpart=`expr $(echo ${rootpart} | sed 's/\/dev\/discs\/disc.*\/part\(.*\)/\1/') - 1`
         else
            grubbootdrive="$(echo ${bootpart} | sed 's/\/dev\/discs\/disc\(.*\)\/part.*/\1/')"
            grubbootpart=`expr $(echo ${bootpart} | sed 's/\/dev\/discs\/disc.*\/part\(.*\)/\1/') - 1`
         fi
         export grubboot="hd${grubbootdrive},${grubbootpart}"
      else
         case ${sel} in
            0) export liloinstall="/dev/discs/disc0/disc";;
            1) [ "${bootpart}" == "" ] && export liloinstall="${rootpart}"
               [ "${bootpart}" != "" ] && export liloinstall="${bootpart}";;
         esac
      fi
   
      # If not configured, then set to the following
      [ -z "${swappart}" ] && swappart="Swap partition not detected."
      [ -z "${bootpart}" ] && bootpart="Use directory on root partition." && boottype="none"
      [ -z "${homepart}" ] && homepart="Use directory on root partition." && hometype="none"
      [ -z "${rootuserpart}" ] && rootuserpart="Use directory on root partition." && rootusertype="none"
      [ -z "${tmppart}" ] && tmppart="Use directory on root partition." && tmptype="none"
      [ -z "${usrpart}" ] && usrpart="Use directory on root partition." && usrtype="none"
      [ -z "${varpart}" ] && varpart="Use directory on root partition." && vartype="none"

      # Is configuration correct?
      if [ "${bootloader}" == "grub" ]; then
         dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "This is your current partition configuration:\nswap  - ${swappart} (swap)\n/     - ${rootpart} (${roottype})\n/boot - ${bootpart} (${boottype})\n/home - ${homepart} (${hometype})\n/root - ${rootuserpart} (${rootusertype})\n/tmp  - ${tmppart} (${tmptype})\n/usr  - ${usrpart} (${usrtype})\n/var  - ${varpart} (${vartype})\n\nThis is your current grub configuration:\nInstalled to: (${grubinstalldrive}${grubinstallpart})\nBoot partition: (${grubboot})\n\nIs this correct?" 19 80
      else
         dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "This is your current partition configuration:\nswap  - ${swappart} (swap)\n/     - ${rootpart} (${roottype})\n/boot - ${bootpart} (${boottype})\n/home - ${homepart} (${hometype})\n/root - ${rootuserpart} (${rootusertype})\n/tmp  - ${tmppart} (${tmptype})\n/usr  - ${usrpart} (${usrtype})\n/var  - ${varpart} (${vartype})\n\nThis is your current lilo configuration:\nInstalled to: ${liloinstall}\n\nIs this correct?" 18 80
      fi
      if [ ${?} -ne 0 ]; then
         validpartconfig="false"
      else
         validpartconfig="true"
         rm -f /tmp/glis/partitionconfig.var
      fi
   done

   # Set to null those partitions which do not exist and export all
   export rootpart; export roottype 
   [ "${swappart}" = "Swap partition not detected." ] && swappart="" ; export swappart
   [ "${bootpart}" = "Use directory on root partition." ] && bootpart="" && boottype="" ; export bootpart ; export boottype
   [ "${homepart}" = "Use directory on root partition." ] && homepart="" && hometype="" ; export homepart ; export hometype
   [ "${rootuserpart}" = "Use directory on root partition." ] && rootuserpart="" && rootusertype="" ; export rootuserpart ; export rootusertype
   [ "${tmppart}" = "Use directory on root partition." ] && tmppart="" && tmptype="" ; export tmppart ; export tmptype
   [ "${usrpart}" = "Use directory on root partition." ] && usrpart="" && usrtype="" ; export usrpart ; export usrtype
   [ "${varpart}" = "Use directory on root partition." ] && varpart="" && vartype="" ; export varpart ; export vartype
   
else
   # Check for empty drive
   partcount=`sfdisk -l /dev/discs/disc0/disc 2>/dev/null | grep "/dev/" | grep -v Disk | grep -vc partition`
   drivestatus=0
   for (( i = 1 ; i <= ${partcount} ; i++ )); do
      parttype=`sfdisk --id /dev/discs/disc0/disc $i 2>/dev/null`
      if [ "${parttype}" != "83" ] && [ "${parttype}" != "82" ] && [ "${parttype}" != "0" ]; then
         drivestatus=`expr ${drivestatus} + 1`
      fi
   done
   if [ ${drivestatus} -gt 0 ]; then
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "***WARNING***: /dev/discs/disc0 is NOT empty AND has partitions that are NOT linux!  This means that there is probably another OS installed on this hard drive! (There are ${drivestatus} non-linux partitions on this drive.)\n\nDo you want to continue and detroy these partitions, loosing ALL DATA on them?" 9 80
      [ $? -ne 0 ] && return 1
   fi
   
   dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait. Partitioning /dev/discs/disc0..." 3 80
   
   # Partition disk
   echo -e ",64,,*\n,${swapsize}\n,\n;\n" | sfdisk -uM -D /dev/discs/disc0/disc 2>/dev/null >/dev/null
   if [ $? -ne 0 ]; then
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "There was an error writing your partition table.  Please reboot and try again." 6 80
      return 1
   fi
   sfdisk --id /dev/discs/disc0/disc 2 82 >/dev/null 2>&1
   if [ $? -ne 0 ]; then
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "There was an error setting your swap partition.  Please reboot and try again." 6 80
      return 1
   fi
   sfdisk --re-read /dev/discs/disc0/disc # Force kernel to re-read partition table
   
   # Check to make sure that the kernel is reading the partition table correctly
   lspartcount=`ls --color=none /dev/discs/disc*/part* | grep -c /dev/discs/disc`
   sfdiskpartcount=`sfdisk -l 2>&1 | grep /part | grep -vc Empty`
   if [ "${sfdiskpartcount}" != "${lspartcount}" ]; then
      dialog --title "Gentoo Linux : Partition Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Kernel is still using the old partition table.  Please reboot and try again." 6 80
      return 1
   fi
   
   # Export partition variables
   export rootpart="/dev/discs/disc0/part3"; export roottype="ext3"; export bootpart="/dev/discs/disc0/part1"; export boottype="ext3"; export swappart="/dev/discs/disc0/part2"
   
   # Export bootloader variables
   export bootloader="grub"; export grubinstalldrive="hd0"; export grubinstallpart=""; export grubboot="hd0,0"
fi
}