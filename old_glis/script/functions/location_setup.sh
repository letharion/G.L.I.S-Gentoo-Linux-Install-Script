#!/bin/bash

location_setup() {
# Time Zone
start="dialog --title \"Gentoo Linux : Time Zone Selection\" --backtitle \"Gentoo Linux \${gentooversion} Installation\" --menu \"Choose your continent/region. Move using [UP] [DOWN],[ENTER] to Select.\" 20 60 12 "
middle=`cat /tmp/glis/script/functions/timezone.tmp | awk -F "/" '{ print $1" \"\"" }' | sort | uniq`
end=" 2>/tmp/glis/menuitem.tmp"
echo ${start}${middle}${end} | sh
if [ "$?" -eq 0 ]; then 
   timezoneregion=$(cat /tmp/glis/menuitem.tmp)
   rm -f /tmp/glis/menuitem.tmp
else
   rm -f /tmp/glis/menuitem.tmp
   return 1
fi 

start="dialog --title \"Gentoo Linux : Time Zone Selection\" --backtitle \"Gentoo Linux \${gentooversion} Installation\" --menu \"Choose your city/timezone. Move using [UP] [DOWN],[ENTER] to Select.\" 20 60 12 "
middle=`cat /tmp/glis/script/functions/timezone.tmp | grep ${timezoneregion}`
end=" 2>/tmp/glis/menuitem.tmp"
echo ${start}${middle}${end} | sh
if [ "$?" -eq 0 ]; then 
   export usertimezone=/usr/share/zoneinfo/$(cat /tmp/glis/menuitem.tmp)
   rm -f /tmp/glis/menuitem.tmp
else
   rm -f /tmp/glis/menuitem.tmp
   return 1
fi 


# Prompt to choose clock setting
dialog --title "Gentoo Linux : Clock Setting" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "You can either set your computer's clock to your own local time or to UTC (GMT) time.\nDo you want to set your clock to local time?" 7 90 
sel=$? 
case $sel in 
   0) export clock=local;; 
   1) export clock=UTC;; 
   *) return 1;; 
esac

# Language
#dialog --title "Gentoo Linux : Language Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "This feature has not yet been implemented." 5 47

# Keymap
#dialog --title "Gentoo Linux : Keymap Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "This feature has not yet been implemented." 5 47
return 0
}