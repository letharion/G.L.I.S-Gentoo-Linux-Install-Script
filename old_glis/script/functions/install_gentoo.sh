install_gentoo() {
# Load functions
source /tmp/glis/script/functions/etc_config.sh
source /tmp/glis/script/functions/chroot_env_set.sh
source /tmp/glis/script/functions/format_partitions.sh
source /tmp/glis/script/functions/mount_partitions.sh
source /tmp/glis/script/functions/download_tarball.sh
source /tmp/glis/script/functions/unpack_tarball.sh
source /tmp/glis/script/functions/prepare_system.sh
source /tmp/glis/script/functions/get_portage_tree.sh
source /tmp/glis/script/functions/bootstrap_system.sh
source /tmp/glis/script/functions/build_system.sh
source /tmp/glis/script/functions/build_kernel.sh
source /tmp/glis/script/functions/implement_config.sh
source /tmp/glis/script/functions/run_install.sh

run_install 1
installstatus=$? ; kernelsetupstatus=0 ; programssetupstatus=0 ; portagesetupstatus=0
while [ ${installstatus} -ne 0 ] ; do
   case ${installstatus} in
      1) errorstage="formating or mounting partitions"; logfile="/tmp/glis/emerge-sync.log";;
      2) errorstage="unpacking tarball"; logfile="/tmp/glis/emerge-sync.log";;
      4) errorstage="updating portage tree"; logfile="/tmp/glis/emerge-sync.log";;
      5) errorstage="bootstrapping system"; logfile="/tmp/glis/emerge-bootstrap.log";;
      6) errorstage="building system"; logfile="/tmp/glis/emerge-system.log";;
      7) errorstage="building kernel"; logfile="/tmp/glis/build-kernel.log";;
      8) errorstage="implementing configuration"; logfile="/tmp/glis/implement-config.log";;
      *) ;;
   esac
   dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "The install failed while ${errorstage}. How would you like to continue?\nMove using [UP] [DOWN],[Enter] to Select:" 16 80 7 Log "View log to determine why the install failed." Kernel "Reconfigure kernel selection options." Programs "Reconfigure which programs to install." Portage "Setup Portage configuration." Restart "Restart the Installation." Shell "Start a shell in the chroot environment." Quit "Exit the install." 2>/tmp/glis/menuitem.tmp
   if [ $? -ne 0 ]; then
      menuitem="Quit"
   else
      menuitem=`cat /tmp/glis/menuitem.tmp`
   fi
   rm -f /tmp/glis/menuitem.tmp
   case ${menuitem} in
      Log)      nano -w ${logfile} ;;
      Kernel)   kernel_setup; kernelsetupstatus=${?};;
      Programs) programs_setup; programssetupstatus=${?};;
      Portage)  portage_setup; portagesetupstatus=${?};;
      Restart)  if [ ${kernelsetupstatus} -eq 0 ] && [ ${programssetupstatus} -eq 0 ] && [ ${portagesetupstatus} -eq 0 ]; then
                   run_install ${installstatus}
                   installstatus=$?
                else
                   if [ ${kernelsetupstatus} -eq 0 ]; then
                      dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "You failed to complete the kernel configuration, please configure it." 7 80
                   elif [ ${programssetupstatus} -eq 0 ]; then
                      dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "You failed to complete the programs configuration, please configure it." 7 80
                   elif [ ${portagesetupstatus} -eq 0 ]; then
                      dialog --title "Gentoo Linux : Main Menu" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "You failed to complete the portage configuration, please configure it." 7 80
                   fi
                fi;;
      Shell)    echo "env-update" > /mnt/gentoo/root/.bashrc
                echo "source /etc/profile" >> /mnt/gentoo/root/.bashrc
                echo -e "clear\necho \"This is a shell to help you fix an installation error.  Do what you need and then type \\\"exit\\\" to return to the menu.\"" >> /mnt/gentoo/root/.bashrc
                chroot /mnt/gentoo /bin/bash
                rm -f /mnt/gentoo/root/.bashrc;;
      *)        break ;; 
   esac
done
}