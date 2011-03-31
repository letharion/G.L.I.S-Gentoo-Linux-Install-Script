# Setup functions
source /tmp/glis/script/functions/write_config.sh
source /tmp/glis/script/functions/network_test.sh
source /tmp/glis/script/functions/network_setup.sh
source /tmp/glis/script/functions/partition_setup.sh
source /tmp/glis/script/functions/stage_setup.sh
source /tmp/glis/script/functions/location_setup.sh
source /tmp/glis/script/functions/kernel_setup.sh
source /tmp/glis/script/functions/programs_setup.sh
source /tmp/glis/script/functions/password_setup.sh
source /tmp/glis/script/functions/portage_setup.sh
source /tmp/glis/script/functions/preinstall_errorcheck.sh

# Install functions
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

menustyle="setup" ; menustatus=1 ; stagesetupstatus=1 ; locationsetupstatus=1 ; networksetupstatus=1 ; partitionsetupstatus=1 ; kernelsetupstatus=1 ; programssetupstatus=1 ; passwordsetupstatus=1 ; portagesetupstatus=1
export gentooversion="1.4"
export arch="x86"
dialog="dialog"
while [ ${menustatus} -ne 0 ] ; do
   while :
   do [ ${networksetupstatus} -ne 0 ] && defaultitem="Network" && break
      [ ${networksetupstatus} -eq 0 ] && [ ${partitionsetupstatus} -ne 0 ] && defaultitem="Partition" && break
      [ ${partitionsetupstatus} -eq 0 ] && [ ${stagesetupstatus} -ne 0 ] && defaultitem="Stage" && break
      [ ${stagesetupstatus} -eq 0 ] && [ ${locationsetupstatus} -ne 0 ] && defaultitem="Location" && break
      [ ${locationsetupstatus} -eq 0 ] && [ ${kernelsetupstatus} -ne 0 ] && defaultitem="Kernel" && break
      [ ${kernelsetupstatus} -eq 0 ] && [ ${programssetupstatus} -ne 0 ] && defaultitem="Programs" && break
      [ ${programssetupstatus} -eq 0 ] && [ ${passwordsetupstatus} -ne 0 ] && defaultitem="Password" && break
      [ ${passwordsetupstatus} -eq 0 ] && [ ${portagesetupstatus} -ne 0 ] && defaultitem="Portage" && break
      [ ${portagesetupstatus} -eq 0 ] && defaultitem="Start" && break
   done
   while [ "${menuitem}" == "" ]; do
      # Which menu should be desplayed?
      if [ ${menustyle} = "setup" ]; then
         ${dialog} --title "Gentoo Linux : Main Menu" --default-item "${defaultitem}" --no-cancel --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "Welcome to Gentoo Linux! To begin installation please select from the following choices (it is best to go in order). Move using [UP] [DOWN],[Enter] to Select" 20 80 11 Network "Configure network settings.                         ${mc3}" Partition "Configure partitions.                               ${mc4}" Stage "Choose which stage to start your install from.      ${mc1}" Location "Choose your timezone, language, and keymap.         ${mc2}" Kernel "Kernel selection options.                           ${mc5}" Programs "Choose which programs to install.                   ${mc6}" Password "Set new root password.                              ${mc7}" Portage "Setup Portage configuration.                        ${mc8}" "" "" Start "Start the Installation." Quit "Exit the install." 2>/tmp/glis/menuitem.tmp
      elif [ ${menustyle} = "install" ]; then
         ${dialog} --title "Gentoo Linux : Main Menu" --no-cancel --backtitle "Gentoo Linux ${gentooversion} Installation" --menu "The install failed while ${errorstage}. How would you like to continue?\nMove using [UP] [DOWN],[Enter] to Select:" 20 80 11 Log "View log to determine why the install failed." Network "Configure network settings.                         ${mc3}" Partition "Configure partitions.                               ${mc4}" Stage "Choose which stage to start your install from.      ${mc1}" Location "Choose your timezone, language, and keymap.         ${mc2}" Kernel "Kernel selection options.                           ${mc5}" Programs "Choose which programs to install.                   ${mc6}" Password "Set new root password.                              ${mc7}" Portage "Setup Portage configuration.                        ${mc8}" "" "" Continue "Continue the installation from the point it stopped." Restart "Restart the installation a previous step of your choice." Shell "Start a shell in the chroot environment." Quit "Exit the install." 2>/tmp/glis/menuitem.tmp
      fi
      if [ $? -ne 0 ]; then
         menuitem="Quit"
      else
         menuitem=`cat /tmp/glis/menuitem.tmp`
      fi
      rm -f /tmp/glis/menuitem.tmp
   done
   case ${menuitem} in
    # Setup options
      Network)   network_setup; export networksetupstatus=${?}; [ ${networksetupstatus} -eq 0 ] && mc3="*DONE*"; [ ${networksetupstatus} -ne 0 ] && mc3="";;
      Partition) partition_setup; export partitionsetupstatus=${?}; [ ${partitionsetupstatus} -eq 0 ] && mc4="*DONE*"; [ ${partitionsetupstatus} -ne 0 ] && mc4="";;
      Stage)     stage_setup; export stagesetupstatus=${?}; [ ${stagesetupstatus} -eq 0 ] && mc1="*DONE*"; [ ${stagesetupstatus} -ne 0 ] && mc1="";;
      Location)  location_setup; export locationsetupstatus=${?}; [ ${locationsetupstatus} -eq 0 ] && mc2="*DONE*"; [ ${locationsetupstatus} -ne 0 ] && mc2="";;
      Kernel)    kernel_setup; export kernelsetupstatus=${?}; [ ${kernelsetupstatus} -eq 0 ] && mc5="*DONE*"; [ ${kernelsetupstatus} -ne 0 ] && mc5="";;
      Programs)  programs_setup;  export programssetupstatus=${?}; [ ${programssetupstatus} -eq 0 ] && mc6="*DONE*"; [ ${programssetupstatus} -ne 0 ] && mc6="";;
      Password)  password_setup;  export passwordsetupstatus=${?}; [ ${passwordsetupstatus} -eq 0 ] && mc7="*DONE*";  [ ${passwordsetupstatus} -ne 0 ] && mc7="";;
      Portage)   portage_setup;  export portagesetupstatus=${?}; [ ${portagesetupstatus} -eq 0 ] && mc8="*DONE*"; [ ${portagesetupstatus} -ne 0 ] && mc8="";;

    # Action Options
      Start)     ${dialog} --title "Gentoo Linux : View Log" --backtitle "Gentoo Linux ${gentooversion} Installation" --msgbox "Please be aware that this installation will take a long time to complete, in some cases more than 24 hours on slower computers (eg. Pentium2 or less).  If the progress bar stops for a long time (even an hour or so), this is normal, especially in Steps 5, 6, and 7.  Do not be alarmed.  The installation has not locked up.  Let it go for a few more hours before rebooting your machine.\n\nHave FUN and welcome to GENTOO!!!" 12 78
                 preinstall_errorcheck; menustatus=$?
                 if [ ${menustatus} -eq 0 ]; then
                    run_install 1
                    installstatus=$?
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
                    menustyle="install"
                    menustatus=${installstatus}
                 fi;;
      
    # Install Options
      Log)        ${dialog} --title "Gentoo Linux : View Log" --backtitle "Gentoo Linux ${gentooversion} Installation" --textbox ${logfile} 18 78 ;;
      Continue)   preinstall_errorcheck; menustatus=$?
                 if [ ${menustatus} -eq 0 ]; then
                    run_install ${installstatus}
                    installstatus=$?
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
                    menustyle="install"
                    menustatus=${installstatus}
                 fi;;
      Restart)   if [ ${installstatus} -gt 1 ]; then
                    case ${installstatus} in
                       2) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\"";;
                       3) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\"";;
                       4) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\" 4 \"Update portage tree\"";;
                       5) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\" 4 \"Update portage tree\" 5 \"Bootstrap system\"";;
                       6) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\" 4 \"Update portage tree\" 5 \"Bootstrap system\" 6 \"Build system\"";;
                       7) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\" 4 \"Update portage tree\" 5 \"Bootstrap system\" 6 \"Build system\" 7 \"Build kernel\"";;
                       8) menuchoices="1 \"Format and mount partitions\" 2 \"Unpack tarball\" 3 \"Prepare system\" 4 \"Update portage tree\" 5 \"Bootstrap system\" 6 \"Build system\" 7 \"Build kernel\" 8 \"Implement configuration\"";;
                    esac
                    start="${dialog} --title \"Gentoo Linux : View Errorlog\" --backtitle \"Gentoo Linux ${gentooversion} Installation\" --menu \"Please choose which step to start from:\" `expr ${installstatus} + 9` 80 ${installstatus} "
                    middle="${menuchoices}"
                    end=" 2>/tmp/glis/menuitem.tmp"
                    echo ${start}${middle}${end} | sh
                    if [ $? -ne 0 ]; then
                       errorcheck=1
                       menustatus=1
                    else
                       installstatus=`cat /tmp/glis/menuitem.tmp`
                    fi
                    rm -f /tmp/glis/menuitem.tmp
                 fi
                 [ "${errorcheck}" != "1" ] && preinstall_errorcheck; menustatus=$?
                 if [ ${menustatus} -eq 0 ]; then
                    run_install ${installstatus}
                    installstatus=$?
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
                    menustyle="install"
                    menustatus=${installstatus}
                 fi;;
      Shell)     echo "env-update" > /mnt/gentoo/root/.bashrc
                 echo "source /etc/profile" >> /mnt/gentoo/root/.bashrc
                 echo -e "clear\necho \"This is a shell to help you fix an installation error.  Do what you need and then type \\\"exit\\\" to return to the menu.\"" >> /mnt/gentoo/root/.bashrc
                 chroot /mnt/gentoo /bin/bash
                 rm -f /mnt/gentoo/root/.bashrc;;
      *)         exit 1 ;; 
   esac
   unset menuitem
done