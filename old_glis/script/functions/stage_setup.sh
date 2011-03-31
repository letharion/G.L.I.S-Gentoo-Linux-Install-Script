#!/bin/bash

stage_setup() {
# Choose stage
dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose from which stage you would like to install. \nMove using [UP] [DOWN],[Enter] to Select" 11 80 3 stage1 "Must build bootstrap and system" stage2 "Bootstrap built, must build system." stage3 "Whole system pre-compiled." 2>/tmp/glis/menuitem.tmp
menuitem=`cat /tmp/glis/menuitem.tmp`
rm -f /tmp/glis/menuitem.tmp
case $menuitem in
   stage1) export installstage=1; export linetotal=5901;;
   stage2) export installstage=2; export linetotal=12587;;
   stage3) export installstage=3; export linetotal=24847;;
   *) return 1;; 
esac

# Choose method
dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose your installation type. \nMove using [UP] [DOWN],[Enter] to Select" 10 80 2 CD "stage ${installstage} tarball on the Gentoo Live CD" Download "stage ${installstage} tarball from a Gentoo Mirror" 2>/tmp/glis/menuitem.tmp
menuitem=`cat /tmp/glis/menuitem.tmp`
rm -f /tmp/glis/menuitem.tmp
case $menuitem in
   CD) export tarballstyle="cd";;
   Download) export tarballstyle="download";;
   *) return 1;; 
esac


# Get tarball from internet or cd
if [ ${tarballstyle} = "download" ] ; then
   cd /tmp/glis
   dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait.  Downloading up-to-date mirror list..." 3 80
   wget -o /tmp/glis/download.log http://www.gentoo.org/main/en/mirrors.xml > /dev/null
   if [ $? -ne 0 ]; then
      rm -f /tmp/glis/mirrors.xml 
      rm -f /tmp/glis/download.log
      dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "There was an error while fetching up-to-date mirror list.  Is your network set up correctly?" 7 80
      return 1
   else
      rm -f /tmp/glis/download.log
   fi
   
   # Choose which mirror to use
   start="dialog --title \"Gentoo Linux : Stage Selection\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --menu \"Choose a mirror to download from. \nMove using [UP] [DOWN],[Enter] to Select\" 20 80 12 "
   middle=`grep "a href" /tmp/glis/mirrors.xml | grep -v doc | sed -n "s/.*href=\"\(.*\)\">\(.*\)<\/a><br>/\1 \"\2\"/gIp"`
   end=" 2>/tmp/glis/menuitem.tmp"
   echo ${start}${middle}${end} | sh
   if [ $? -ne 0 ]; then
      rm -f /tmp/glis/menuitem.tmp
      rm -f /tmp/glis/mirrors.xml
      return 1
   else
      export mirrorchoice=`cat /tmp/glis/menuitem.tmp`
      rm -f /tmp/glis/menuitem.tmp
      rm -f /tmp/glis/mirrors.xml
   fi
else
   if [ ! -f /mnt/cdrom/stages/stage${installstage}-${arch}-${gentooversion}.tar.bz2 ]; then
      dialog --title "Gentoo Linux : Unpacking Tarball" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Tarball not found on your cdrom.  Please use CD with tarball or download tarball." 7 80
      return 1
   fi
fi
return 0
}
