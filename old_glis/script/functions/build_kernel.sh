#!/bin/bash

build_kernel() {
# Kernel install routine
rm -f /tmp/glis/build-kernel.log

if [ ${customkernel} = "true" ]; then

   # This will make a custom kernel
   # Emerge kernel source
   dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait.  Downloading and patching ${kernelsource}..." 3 80
   chroot_env_set "emerge ${kernelsource}"
   chroot /mnt/gentoo >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching ${kernelsource}!" >> /tmp/glis/build-kernel.log && return 1

   # Check which type the kernel is and which dir the kernel is in and store it in variables
   if [ -d /mnt/gentoo/usr/src/linux-beta ]; then
      mkdir /mnt/gentoo/sys
      export kerneldir="/usr/src/linux-beta"
      export kerneltype="beta"
   elif [ -d /mnt/gentoo/usr/src/linux ]; then
      export kerneldir="/usr/src/linux"
      export kerneltype="stable"
   else
      echo "*** Error: no kernel directory found!" >> /tmp/glis/build-kernel.log && return 1
   fi

   # If /tmp/glis/kernelconfig exists, make it the default kernel config
   if [ -f /tmp/glis/kernelconfig ]; then
      cp /tmp/glis/kernelconfig /mnt/gentoo${kerneldir}/.config
      rm -f /tmp/glis/kernelconfig
   fi

   # Check for .config, and make accordingly
   if [ -f /mnt/gentoo${kerneldir}/.config ]; then
      chroot_env_set "cd ${kerneldir}" "make oldconfig"
   else
      chroot_env_set "cd ${kerneldir}" "nano -w /etc/modules.autoload" "make menuconfig"
   fi
   chroot /mnt/gentoo
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error configuring ${kernelsource}!" >> /tmp/glis/build-kernel.log && return 1

   # Build kernel
   dialog --title "Gentoo Linux : Stage Selection" --backtitle "Gentoo Linux ${gentooversion} Installation" --infobox "Please wait.  Building ${kernelsource}..." 3 80
   if [ ${kerneltype} != "beta" ] ; then
      chroot_env_set "cd ${kerneldir}" "make dep && make clean bzImage modules modules_install"
   else
      chroot_env_set "cd ${kerneldir}" "make dep && make clean bzImage modules modules_install" # Beta kernels do not use 'make dep'
   fi
   chroot /mnt/gentoo >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error building ${kernelsource}!" >> /tmp/glis/build-kernel.log && return 1

   # Install kernel
   mv /mnt/gentoo${kerneldir}/arch/i386/boot/bzImage /mnt/gentoo/boot/vmlinuz >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error copying kernel to /boot!" >> /tmp/glis/build-kernel.log && return 1

else

   # This will make a generic kernel
   # Get utility to build generic kernel
   chroot_env_set "emerge genkernel"
   chroot /mnt/gentoo >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error fetching genkernel utility!" >> /tmp/glis/build-kernel.log && return 1
   echo 5

   # Build generic kernel
   start_generic_build() {
   chroot_env_set "genkernel ${kernelsource}"
   chroot /mnt/gentoo >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   }
   
   rm -f /tmp/glis/build-kernel-exitstatus.tmp
   start_generic_build &
   while [ ! -f /tmp/glis/build-kernel-exitstatus.tmp ]; do
      echo `expr 5 + $(expr $(grep -c "Moving bzImage" /tmp/glis/build-kernel.log) \* 10) + $(expr $(grep -c "Compiling kernel" /tmp/glis/build-kernel.log) + $(grep -c "Compiling modules" /tmp/glis/build-kernel.log) + $(grep -c "Modules install" /tmp/glis/build-kernel.log)) \* 25`
      sleep 10
   done
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error building kernel!" >> /tmp/glis/build-kernel.log && return 1
   echo 95

   # Install kernel
   mv /mnt/gentoo/kernel* /mnt/gentoo/boot/vmlinuz >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error copying kernel to /boot!" >> /tmp/glis/build-kernel.log && return 1

   # Install initrd
   mv /mnt/gentoo/initrd* /mnt/gentoo/boot/initrd >> /tmp/glis/build-kernel.log 2>&1
   echo $? > /tmp/glis/build-kernel-exitstatus.tmp
   [ $(cat /tmp/glis/build-kernel-exitstatus.tmp) -ne 0 ] && echo "*** Error copying initrd to /boot!" >> /tmp/glis/build-kernel.log && return 1
fi
echo 100
}