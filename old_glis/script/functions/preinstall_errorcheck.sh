#!/bin/bash

preinstall_errorcheck() {
# Check to see if the install stage has been setup
if [ ${stagesetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Install stage has not been setup. Please configure stage selection." 6 80
   return 1
fi

# Check to see if the timezone, language, and keymap have been setup
if [ ${locationsetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your location is not configured correctly.  Please configure location settings." 6 80
   return 1
fi

# Check to see if the network has been configured and is working
if [ ${networksetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your network is not configured correctly.  Please configure network settings." 6 80
   return 1
else
   network_test
   [ ${?} -ne 0 ] && return 1
fi

# Check to see if partitions have been setup
if [ ${partitionsetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your partitions are not configured correctly.  Please configure partition settings." 6 80
   return 1
fi

# Check to see if kernel has been chosen
if [ ${kernelsetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your kernel is not configured correctly.  Please configure kernel settings." 6 80
   return 1
fi

# Check to see if programs were chosen
if [ ${programssetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "You did not choose programs to install yet.  Please configure program settings." 6 80
   return 1
fi

# Check to see if password was chosen
if [ ${passwordsetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your password is not configured correctly.  Please configure password settings." 6 80
   return 1
fi

# Check to see if portage was setup
if [ ${portagesetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "You have not yet set up Portage.  Please configure Portage." 6 80
   return 1
fi
return 0
}