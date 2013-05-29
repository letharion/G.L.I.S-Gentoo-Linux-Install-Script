build_kernel()
{
source ${GLIS_CONFIG}

# Set time zone
# If TIME_ZONE is not set or does not exist, default to UTC
if [ "${TIME_ZONE}" != "" ] && \
   [ -f /mnt/gentoo/usr/share/zoneinfo/${TIME_ZONE} ]; then
   ln -sf /mnt/gentoo/usr/share/zoneinfo/${TIME_ZONE} /mnt/gentoo/etc/localtime
else
   ln -sf /mnt/gentoo/usr/share/zoneinfo/UTC /mnt/gentoo/etc/localtime
fi

# Configure fstab
etc_config "/etc/fstab"
if [ $? -ne 0 ]; then
   echo "!!! Error #0801: Could not set fstab."   
   return 1
fi

# Emerge kernel source
chroot /mnt/gentoo emerge ${EMERGE_OPTIONS} ${KERNEL_SOURCE}
if [ $? -ne 0 ]; then
   echo "!!! Error #0802: Could not emerge kernel ${KERNEL_SOURCE}."
   return 1
fi

# Check which type the kernel is and which dir the kernel is in and
# store it in variables
KERNEL_VER=$(ls -1 /mnt/gentoo/usr/src | grep -E "linux-3.*" | sed 's/^linux-\(3.*\)/\1/g')

if [ -z ${KERNEL_VER} ]; then
   echo "!!! Error #0803: No kernel sources found!"
   return 1
fi
   
# If KERNEL_CONFIG is set, make it the default kernel config
if [ "${KERNEL_CONFIG}" != "" ] && [ -f ${KERNEL_CONFIG} ]; then
   cp ${KERNEL_CONFIG} /mnt/gentoo/usr/src/linux/.config
   GENKERNEL_CONFIG="--kernel-config=${KERNEL_CONFIG}"
fi


if [ ${GENKERNEL} -eq 1 ]; then

   # This will make a generic kernel
   # Get utility to build generic kernel
   chroot /mnt/gentoo emerge ${EMERGE_OPTIONS} genkernel
   if [ $? -ne 0 ]; then
      echo "!!! Error #0804: Could not emerge genkernel."
      return 1
   fi
   
   # Use genkernel
   chroot /mnt/gentoo genkernel all --clean --mrproper ${GENKERNEL_CONFIG}
   if [ $? -ne 0 ]; then
      echo "!!! Error #0805: Could not execute genkernel."
      return 1
   fi
   
   # Install kernel and initrd
   mv /mnt/gentoo/boot/kernel* /mnt/gentoo/boot/vmlinuz
   if [ $? -ne 0 ]; then
      echo "!!! Error #0806: Could not install vmlinuz to /boot"
      return 1
   fi
   mv /mnt/gentoo/boot/initrd* /mnt/gentoo/boot/initrd
   if [ $? -ne 0 ]; then
      echo "!!! Error #0807: Could not install initrd to /boot"
      return 1
   fi

else

   # Check for .config, and make accordingly
   if [ -f /mnt/gentoo/usr/src/linux/.config ]; then
      echo -e "cd /usr/src/linux\nmake oldconfig" > /mnt/gentoo/tmp/setupkernel
   else
      echo -e "cd /usr/src/linux\nmake menuconfig" > \
         /mnt/gentoo/tmp/setupkernel
   fi
   
   chroot /mnt/gentoo /bin/bash /tmp/setupkernel
   EXITSTATUS=$?
   rm -f /mnt/gentoo/tmp/setupkernel
   if [ ${EXITSTATUS} -ne 0 ]; then
      echo "!!! Error #0808: Could not write kernel config."
      return 1
   fi

   # Build kernel
   echo "cd /usr/src/linux" > /mnt/gentoo/tmp/buildkernel
   if [ "${KERNEL_VER}" == "2.6" ]; then
      echo "make clean bzImage modules modules_install" >> \
         /mnt/gentoo/tmp/buildkernel
   else
      echo "make dep && make clean bzImage modules modules_install" >> \
         /mnt/gentoo/tmp/buildkernel
   fi
   
   chroot /mnt/gentoo bash /tmp/buildkernel
   EXITSTATUS=$?
   rm -f /mnt/gentoo/tmp/buildkernel
   if [ ${EXITSTATUS} -ne 0 ]; then
      echo "!!! Error #0809: Could not build kernel."
      return 1
   fi
   
   # Install kernel
   cp /mnt/gentoo/usr/src/linux/arch/x86/boot/bzImage /mnt/gentoo/boot/vmlinuz
   if [ $? -ne 0 ]; then
      echo "!!! Error #0810: Could not install vmlinuz to /boot."
      return 1
   fi
fi

# Setup kernel modules
if [ "${KERNEL_MODULES}" != "" ]; then 
   # Now modules.autoload are split for 2.4 and 2.6 kernels.
   # Warning: Many modules names changed in 2.6, and there several
   # new ones (like via-agp for via agpgart).
   echo ${KERNEL_MODULES} | sed "s/,/\n/g" >> \
      /mnt/gentoo/etc/modules.autoload.d/kernel-${KERNEL_VER}
fi
}
