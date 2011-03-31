#!/bin/bash

portage_setup() {
# Check to see if the network has been configured and is working
if [ ${networksetupstatus} -ne 0 ] ; then
   dialog --title "Gentoo Linux : Installation" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your network is not configured correctly.  Please configure network settings." 6 80
   return 1
fi
network_test; [ ${?} -ne 0 ] && return 1

parse_use_variables() {
dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait.  Downloading up-to-date USE Flags..." 3 80
wget -P /tmp/glis http://www.gentoo.org/dyn/use-index.xml 2>/dev/null
if [ $? -ne 0 ]; then
   rm -f /tmp/glis/use-index.xml
   return 1
fi
grep tableinfo /tmp/glis/use-index.xml | grep "</td>" | sed "s/.*tableinfo\">\(.*\)<\/td>/\1/" > /tmp/glis/use1
grep tableinfo /tmp/glis/use-index.xml | grep -v "</td>" | sed "s/.*tableinfo\">\(.*\)/\"\1\"/" > /tmp/glis/use2
paste -d \; /tmp/glis/use1 /tmp/glis/use2 | grep -v internal | sort > /tmp/glis/dialogusevariables.tmp
rm -f /tmp/glis/use*
return 0
}

# Set USE variables
dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "Would you like to customize your USE flags?" 6 80
if [ $? -eq 0 ]; then
   # Process USE variables
   repeat="true"
   while [ ${repeat} = "true" ]; do
      repeat="false"
      parse_use_variables 
      if [ $? -ne 0 ]; then
         dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "There was an error while downloading up-to-date USE variables.  Would you like to try again?" 7 80
         if [ $? -eq 0 ]; then
            repeat="true"
         else
            return 1
         fi
      fi
   done

   # Choose USE variables
   repeat="true"
   while [ ${repeat} = "true" ]; do
      start="dialog --separate-output --title \"Gentoo Linux : Portage Setup\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --checklist \"Choose the USE variables you prefer.\nMove using [UP] [DOWN],[Space] to Select, and [Enter] to Continue\" 20 80 12 "
      middle=`cat /tmp/glis/dialogusevariables.tmp | awk -F \; '{ print $1" "$2" off" }'`
      end=" 2>/tmp/glis/checklist.tmp"
      echo ${start}${middle}${end} | sh
      if [ ${?} -ne 0 ]; then
         rm -f /tmp/glis/checklist.tmp
         rm -f /tmp/glis/dialogusevariables.tmp
         return 1
      else
         mv /tmp/glis/checklist.tmp /tmp/glis/posativeusevars.tmp
      fi
      
      # Remove variables already chosen for the negative list
      cat /tmp/glis/dialogusevariables.tmp | awk -F \; '{ print $1 }' > /tmp/glis/dialogvarsonly.tmp
      cat /tmp/glis/dialogvarsonly.tmp /tmp/glis/posativeusevars.tmp | sort | uniq -u > /tmp/glis/dialogvarsonlycomplete.tmp
      rm -f /tmp/glis/dialogvarsonly.tmp      
      
      # Choose the USE variables NOT to use
      start="dialog --separate-output --title \"Gentoo Linux : Portage Setup\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --checklist \"Choose the USE variables you do NOT want the system to use (ie. -gtk).\nMove using [UP] [DOWN],[Space] to Select, and [Enter] to Continue\" 20 80 12 "
      middle=`join -t \; /tmp/glis/dialogvarsonlycomplete.tmp /tmp/glis/dialogusevariables.tmp | awk -F \; '{ print "-"$1" "$2" off" }'`
      end=" 2>/tmp/glis/checklist.tmp"
      echo ${start}${middle}${end} | sh
      if [ ${?} -ne 0 ]; then
         rm -f /tmp/glis/checklist.tmp
         rm -f /tmp/glis/dialogusevariables.tmp
         rm -f /tmp/glis/posativeusevars.tmp
         rm -f /tmp/glis/dialogvarsonlycomplete.tmp
         return 1
      else
         mv /tmp/glis/checklist.tmp /tmp/glis/negativeusevars.tmp
         rm -f /tmp/glis/dialogvarsonlycomplete.tmp
      fi
      export usevar="`echo $(cat /tmp/glis/posativeusevars.tmp ; cat /tmp/glis/negativeusevars.tmp)`"
      rm -f /tmp/glis/posativeusevars.tmp
      rm -f /tmp/glis/negativeusevars.tmp
      dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "You have selected USE=\"`echo ${usevar}`\".\n\nIs this correct?" 10 80
      [ $? -eq 0 ] && break
   done
   rm -f /tmp/glis/dialogusevariables.tmp
else
   export usevar="X gtk gnome -alsa"
fi

# Set CHOST
   dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Select your desired CHOST settings:" 11 80 4 i386-pc-linux-gnu "386" i486-pc-linux-gnu "486" i586-pc-linux-gnu "Pentium, K6-(all), Eden C3/Ezra" i686-pc-linux-gnu "Pentium (Pro,2,3,4), Celeron, Athlon (all), Duron" 2>/tmp/glis/input.tmp
   [ $? -ne 0 ] && return 1
   export chostvar=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp

# Set CFLAGS
cflagsvar=""
while [ -z "${cflagsvar}" ] ; do
   dialog --title "Gentoo Linux : Portage Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "${emptyconfig}Enter your desired CFLAGS settings:" 8 80 "-march=pentium3 -O3 -pipe -fomit-frame-pointer" 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   case $sel in
      0) export cflagsvar=$na ;;
      1) return 1;;
      255) return 1;;   
   esac
   emptyconfig="You MUST set CFLAGS settings. "
done
unset emptyconfig

# Set CXXFLAGS
export cxxflagsvar="\${CFLAGS}"

# Set GENTOO_MIRRORS
if [ "${mirrorchoice}" != "" ]; then
   export gentoomirrorsvar="${mirrorchoice}"
else
   selectmirror="true"
   while [ "${selectmirror}" = "true" ]; do
      dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait.  Downloading up-to-date mirrors..." 3 80
      wget -P /tmp/glis http://www.gentoo.org/main/en/mirrors.xml 2>/dev/null
      if [ $? -ne 0 ]; then
         rm -f /tmp/glis/mirrors.xml
         dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "There was an error while fetching up-to-date mirror list.  Is your network set up correctly?" 7 80
         return 1
      fi
   
      # Choose which mirror to use
      start="dialog --separate-output --title \"Gentoo Linux : Stage Selection\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --checklist \"Choose mirror(s) to download from or hit [Enter] to skip.\nMove using [UP] [DOWN],[Space] to Select, and [Enter] to Continue:\" 20 80 11 "
      middle=`grep "a href" /tmp/glis/mirrors.xml | grep -v doc | sed -n "s/.*href=\"\(.*\)\">\(.*\)<\/a><br>/\1 \"\2\" off/gIp"`
      end=' 2>/tmp/glis/menuitem.tmp'
      echo ${start}${middle}${end} | sh
      if [ $? -ne 0 ]; then
         rm -f /tmp/glis/menuitem.tmp
         rm -f /tmp/glis/mirrors.xml
         return 1
      else
         export gentoomirrorsvar=`echo $(cat /tmp/glis/menuitem.tmp)`
         rm -f /tmp/glis/menuitem.tmp
         rm -f /tmp/glis/mirrors.xml
         dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "You have chosen: GENTOO_MIRRORS=\"${gentoomirrorsvar}\"\n\nIs this correct?" 10 80
         [ $? -eq 0 ] && selectmirror="false"
      fi
   done
fi
return 0
}