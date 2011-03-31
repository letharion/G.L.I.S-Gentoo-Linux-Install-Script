#!/bin/bash

# This fuction is a routine to set the appropriate commands to .bashrc
chroot_env_set() {
# Make sure that these commands are run each time chroot is run
echo "env-update" > /mnt/gentoo/root/.bashrc
echo "source /etc/profile" >> /mnt/gentoo/root/.bashrc
while [ "$1" != "" ]; do
   echo -e "$1" >> /mnt/gentoo/root/.bashrc
   shift
done
echo -e "exit \$?" >> /mnt/gentoo/root/.bashrc
}
