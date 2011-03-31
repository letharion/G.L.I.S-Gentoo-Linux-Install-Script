#!/bin/bash

# Function to test network connectivity
network_test() {
ping -c 1 ${gateway} > /dev/null
[ $? -ne 0 ] && dialog --title "Gentoo Linux : Network Error" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Your network IS configured, but I cannot connect to the internet.  Please check cable/settings and re-configure." 6 80 && return 1
return 0
}