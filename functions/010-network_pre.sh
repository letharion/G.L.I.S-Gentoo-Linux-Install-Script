# Configure the network used during the install process. This has nothing to
# Do with the systems network config. That is done in 100-implement_config
network_pre()
{
source ${GLIS_CONFIG}

# If NET_INSTALL_TYPE is not set then make it equal to 0 and use ethernet.
if [ -z "${NET_INSTALL_TYPE}" ]; then
   write_config "NET_INSTALL_TYPE" "NET_INSTALL_TYPE=0" ${GLIS_CONFIG} "="
   NET_INSTALL_TYPE=0
elif [ ${NET_INSTALL_TYPE} -eq 3 ]; then
   # We can skip the rest of this step since no networking should be configured
   return 0
fi

if [ ${NET_INSTALL_TYPE} -eq 0 ] && [ ! -z "${IFACE_PRE}" ] && \
   [ ! -z "${IFACE_IP_PRE}" ] && [ ! -z "${IFACE_NETMASK_PRE}" ] && \
   [ ! -z "${IFACE_BROADCAST_PRE}" ] && [ ! -z "${IFACE_GATEWAY_PRE}" ] && \
   [ ! -z "${NAMESERV_PRE}" ]; then

   ifconfig ${IFACE_PRE} ${IFACE_IP_PRE} broadcast ${IFACE_BROADCAST_PRE} \
      netmask ${IFACE_NETMASK_PRE}
   if [ $? -ne 0 ]; then
      echo "!!! Error #0101: Error bringing up ${IFACE_NETMASK_PRE}."
      return 1
   fi

   # Check if the default route has already been set. Delete it if it has been.
   exists=`route | grep '^default'`
   if [ "$exists" != "" ]; then
      route del -net default
   fi

   route add -net default gw ${IFACE_GATEWAY_PRE} netmask 0.0.0.0 metric 1 \
       ${IFACE_PRE}
   if [ $? -ne 0 ]; then
      echo "!!! Error #0102: Error setting default route."
      return 1
   fi
   
   ping -c 1 ${IFACE_GATEWAY_PRE}
   if [ $? -ne 0 ]; then
      echo "!!! Error #0103: Could not find network."
      return 1
   fi

   # Setup the nameservers
   rm -f /etc/resolv.conf
   for nameserver in ${NAMESERV_PRE}; do
      echo "nameserver $nameserver" >> /etc/resolv.conf
   done
      
elif [ ${NET_INSTALL_TYPE} -eq 0 ]; then
   killall dhcpcd
   dhcpcd ${IFACE_PRE}
   if [ $? -ne 0 ]; then
      echo "!!! Error #0104: Error starting DHCP."
      return 1
   fi   

   ping -c 1 $(grep GATEWAY /etc/dhcpc/dhcpcd-eth0.info | cut -d "=" -f2)
   if [ $? -ne 0 ]; then
      echo "!!! Error #0103: Could not find network."
      return 1
   fi

elif [ ${NET_INSTALL_TYPE} -eq 2 ]; then
   wvdialconf /etc/wvdial.conf
   if [ $? -ne 0 ]; then
      echo "!!! Error #0105: Error configuring modem"
      return 1
   fi

   write_config "Phone" "Phone=${DIALUP_NUMBER}" "/etc/wvdial.conf" "="
   write_config "Username" "Username=${DIALUP_USERNAME}" "/etc/wvdial.conf" "="
   write_config "Password" "Password=${DIALUP_PASSWORD}" "/etc/wvdial.conf" "="

   if [ "${DIALUP_ON_DEMAND}" != "1" ]; then
      wvdial --config /etc/wvdial.conf &
      # Wait for the modem to connect
      sleep 25
   fi
fi

# If we have any nfs partitions then we'll need to start portmap
for (( i=0; ${i} < ${#PARTITION[@]}; i++ )); do
   if [ $(echo ${PARTITION[${i}]} | grep -c ":") -gt 0 ]; then
      ebegin "Starting portmap"
      start-stop-daemon --start --quiet --exec /sbin/portmap
      eend $?
      break
   fi
done
}
