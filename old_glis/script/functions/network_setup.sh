#!/bin/bash

# Function to setup network interface
network_setup() {
# Choose interface
dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Choose a network interface to configure. Move using [UP] [DOWN],[Enter] to Select." 12 60 4 eth0 "" eth1 "" eth2 "" eth3 "" 2>/tmp/glis/menuitem.tmp
menuitem=`cat /tmp/glis/menuitem.tmp`
rm -f /tmp/glis/menuitem.tmp
case ${menuitem} in
   eth0) export nic=eth0;;
   eth1) export nic=eth1;;
   eth2) export nic=eth2;;
   eth3) export nic=eth3;;
   *) return 1 ;;
esac

# Setup chosen interface (this is borrowed and modified, with thanks, from /usr/sbin/net-setup on the Gentoo Live CD)
dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Time to set up the ${nic} interface! You can use DHCP to automatically configure a network interface or you can specify an IP and related settings manually. Choose one option:" 12 60 2 DHCP "Use DHCP to auto-detect my network settings" Static "Specify an IP address manually" 2>/tmp/glis/${nic}.1
export nettype=`cat /tmp/glis/${nic}.1`
rm -f /tmp/glis/${nic}.1
case ${nettype} in
DHCP)
	/sbin/dhcpcd -t 10 ${nic}
	[ ${?} -ne 0 ] && dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Automatic configuration failed.  Please check your network cable and try again." 6 80 && return 1
    gateway=`grep GATEWAY /etc/dhcpc/dhcpcd-${nic}.info | sed "s/.*=\(.*\)/\1/"`
    hostname=`grep HOSTNAME /etc/dhcpc/dhcpcd-${nic}.info | sed "s/.*=\(.*\)/\1/"`
    domain=`grep DOMAIN /etc/dhcpc/dhcpcd-${nic}.info | sed "s/.*='\(.*\)'/\1/"`
    export ip="127.0.0.1";;
Static)
	dialog --title "Gentoo Linux : IP address" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Please enter an IP address for ${nic}:" 20 50 "192.168.0.2" 2> /tmp/glis/${nic}.IP
	dialog --title "Gentoo Linux : Broadcast address" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Please enter a Broadcast address for ${nic}:" 20 50 "192.168.0.255" 2> /tmp/glis/${nic}.B
	dialog --title "Gentoo Linux : Network mask" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Please enter a Network Mask for ${nic}:" 20 50 "255.255.255.0" 2> /tmp/glis/${nic}.NM
	dialog --title "Gentoo Linux : Gateway" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Please enter a Gateway for ${nic} (hit enter for none):" 20 50 2> /tmp/glis/${nic}.GW
	dialog --title "Gentoo Linux : DNS server" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Please enter a name server to use (hit enter for none):" 20 50 2> /tmp/glis/${nic}.NS
	/sbin/ifconfig ${nic} `cat /tmp/glis/${nic}.IP` broadcast `cat /tmp/glis/${nic}.B` netmask `cat /tmp/glis/${nic}.NM`
	myroute=`cat /tmp/glis/${nic}.GW`
	if [ "$myroute" != "" ]
	then
		/sbin/route add default gw $myroute dev ${nic} netmask 0.0.0.0 metric 1	
	fi
	myns="`cat /tmp/glis/${nic}.NS`"
	if [ "$myns" = "" ]
	then
		: > /etc/resolv.conf
	else
		echo "nameserver $myns" > /etc/resolv.conf
	fi
	export ip=`cat /tmp/glis/${nic}.IP`
        export broadcast=`cat /tmp/glis/${nic}.B`
        export netmask=`cat /tmp/glis/${nic}.NM`
        export gateway=`cat /tmp/glis/${nic}.GW`
	rm -f /tmp/glis/${nic}.*
	hostname=""
	domain="";;
*)
	return 1;;
esac

# Choose hostname
while [ -z ${hostname} ] ; do
   dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "${emptyconfig}Enter your hostname please (ie. 'host', NOT 'host.gentoo.org'):" 9 80 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   [ ${sel} -ne 0 ] && return 1
   export hostname=$na
   emptyconfig="You MUST have a hostname. "
done
unset emptyconfig

# Domain
while [ -z ${domain}  ] ; do
   dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "${emptyconfig}Enter your domain please (ie. 'gentoo.org'):" 9 80 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   [ ${sel} -ne 0 ] && return 1
   export domain=$na
   emptyconfig="You MUST have a domain. "
done
unset emptyconfig

# Proxy
dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --yesno "Do you want to set a proxy?" 5 80
if [ $? -eq 0 ]; then

   # HTTP Proxy
   dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Enter your http proxy (ie. 'machine.company.com:1234' or leave blank for none):" 9 80 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   [ ${sel} -ne 0 ] && return 1
   export http_proxy="$na"

   # FTP Proxy
   dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Enter your ftp proxy (ie. 'machine.company.com' or leave blank for none):" 9 80 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   [ ${sel} -ne 0 ] && return 1
   export ftp_proxy="$na"

   # RSYNC Proxy
   dialog --title "Gentoo Linux : Network Setup" --backtitle "Gentoo Linux ${gentooversion} Installation" --inputbox "Enter your rsync proxy (ie. 'machine.company.com' or leave blank for none):" 9 80 2>/tmp/glis/input.tmp
   sel=$?
   na=`cat /tmp/glis/input.tmp`
   rm -f /tmp/glis/input.tmp
   [ ${sel} -ne 0 ] && return 1
   export RSYNC_PROXY="$na"
fi

network_test
return $?
}