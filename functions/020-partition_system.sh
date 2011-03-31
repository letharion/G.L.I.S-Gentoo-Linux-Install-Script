partition_system() {
###############################################################
# This file needs to be divided into three different sections #
# 1. Partitioning                                             #
# 2. Formating                                                #
# 3. Mounting                                                 #
#                                                             #
# Each one of these sections should operate according to the  #
# guidlines set out in the config file.                       #
#                                                             #
# PLEASE REMOVE THIS BOX WHEN COMPLETE                        #
###############################################################

#-----------#
# Functions #
#-----------#
   
   # This is a function to read /dev/hda1 type input and echo "/dev/hda 1" type output
   get_drive_and_part() {
   drive="$(echo "$1" | sed -e "s/\(\/dev\/[sh]d[a-z]\)[0-9]*/\1/" -e "s/\(\/dev\/[sh]d[a-z]\)$/\1/" -e "s/\(\/dev\/discs\/disc[0-9]*\)\/[pd][ai][rs][tc].*/\1\/disc/")"
   part="$(echo "$1" | sed -n -e "s/\/dev\/[sh]d[a-z]\([0-9]\)/\1/p" -e "s/\/dev\/discs\/disc[0-9]\/part\([0-9]\)/\1/p")"
   if [ "${drive}" == "" ] || [ "${part}" == "" ]; then
      return 1
   fi
   
   # Return correct values
   echo "${drive} ${part}"
   return 0
   }

   # Create partition table (for drive passed to it)
   create_partition_table() {
   CURRENT_DRIVE="$(get_drive_and_part "$1" | cut -d " " -f1)"                                                           # The drive in "/dev/hda" format
   CURRENT_TABLE="/tmp/partition_table/$(echo ${CURRENT_DRIVE} | sed -n "s/\//-/gp")"                                    # The file name of the current table

   # Make sure that parted can read the specified drive before continuing
   drvtest=$(parted -s ${CURRENT_DRIVE} print)
   if [ $? != 0 ]; then
      echo "!!! Error #0201: Parted could not read ${CURRENT_DRIVE}."
      echo "Parted output: ${drvtest}"
      return 1
   fi
   CURRENT_DRIVE_SIZE="$(parted -s ${CURRENT_DRIVE} print | grep "Disk geometry for" | cut -d " " -f5 | cut -d "-" -f2)" # The current size of the drive

   rm -f /tmp/temp_table
   for (( i=0 ; i < ${#PARTITION[@]} ; i++ )); do
      # Write temporary table
      # We should only write the partition if it's on the same drive
      tmp_drive=$(get_drive_and_part ${PARTITION[${i}]} | cut -d " " -f1)
      if [ "${CURRENT_DRIVE}" == "${tmp_drive}" ]; then
         echo "$(get_drive_and_part ${PARTITION[${i}]} | cut -d " " -f2):${PARTITION_SIZE[${i}]}:${PARTITION_TYPE[${i}]}" >> /tmp/temp_table
         if [ $? -ne 0 ]; then
            echo "Error: unable to write temporary partition table"
            rm -f /tmp/temp_table
            return 1
         fi
      fi
   done
   
   # Sort partition table
   rm -f ${CURRENT_TABLE}.unprocessed
   i=1
   while read RECORD ; do
      if [ "$(echo ${RECORD} | grep "^${i}:")" != "" ]; then
         echo "${RECORD}" >> ${CURRENT_TABLE}.unprocessed
      elif [ "$(cat /tmp/temp_table | grep "^${i}:")" != "" ]; then
         echo "$(cat /tmp/temp_table | grep "^${i}:")" >> ${CURRENT_TABLE}.unprocessed
      else
         echo "Error: you did not define drive ${CURRENT_DRIVE} partition ${i}"
         rm -f /tmp/temp_table
         rm -rf /tmp/partition_table*
         return 1
      fi
      i=$(expr ${i} + 1)
   done < /tmp/temp_table
   rm -f /tmp/temp_table
   
   # Process partition table
   while read RECORD ; do
      CURRENT_PART=$(echo ${RECORD} | cut -d ":" -f1)
      CURRENT_PART_TYPE=$(echo ${RECORD} | cut -d ":" -f3)
      
      # If size of current part is in MBs then just store it
      if [ "$(echo "$(echo ${RECORD} | cut -d ":" -f2)" | sed -n "s/.*\(.\)$/\1/p")" == "M" ]; then
         CURRENT_PART_SIZE="$(echo "$(echo ${RECORD} | cut -d ":" -f2)" | sed -n "s/\(.*\).$/\1/p")"
		
      # If the size of current part is in %, then calculate and store it
      elif [ "$(echo "$(echo ${RECORD} | cut -d ":" -f2)" | sed -n "s/.*\(.\)$/\1/p")" == "%" ]; then
         PERCENT=$(echo "$(echo ${RECORD} | cut -d ":" -f2)" | sed -n "s/\(.*\).$/\1/p")
         CURRENT_PART_SIZE="$(echo "(${PERCENT} * ${CURRENT_DRIVE_SIZE}) / 100" | bc)"
			
      # If the partition is set to take the rest of the drive, just transfer the character
      elif [ "$(echo ${RECORD} | cut -d ":" -f2)" == "@" ]; then
         CURRENT_PART_SIZE="@"

      # If the partition size is NULL, we are going to pull the size from parted (and keep the partition)
      elif [ "$(echo ${RECORD} | cut -d ":" -f2)" == "" ]; then
         CURRENT_PART_SIZE=""
			
      # Else give an error
      else
         echo "Error: \"$(echo ${RECORD} | cut -d ":" -f2)\" is not a valid partition size format."
         rm -rf /tmp/partition_table*
         return 1
      fi
      
      # If CURRENT_PART_SIZE is NULL it is because we are going to keep the partition
      # Therefore, we need to get the start and end points from parted
      # We also need to make sure that the partition doesn't get deleted
      if [ "${CURRENT_PART_SIZE}" == "" ]; then
         if [ "$(parted -s ${CURRENT_DRIVE} print | grep "^${CURRENT_PART}")" == "" ]; then
            echo "Error: you wanted to keep drive ${CURRENT_DRIVE} partition ${CURRENT_PART} but it does not exist"
            rm -rf /tmp/partition_table*
            return 1
         fi
         CURRENT_PART_START=$(parted -s ${CURRENT_DRIVE} print | grep "^${CURRENT_PART}" | awk -F " " '{ print $2 }')
         CURRENT_PART_END=$(parted -s ${CURRENT_DRIVE} print | grep "^${CURRENT_PART}" | awk -F " " '{ print $3 }')
         CREATE_CURRENT_PART=0

      # If CURRENT_PART_SIZE is NOT NULL it is because we are going to create the partition
      # This means we also need to calculate CURRENT_PART_START and CURRENT_PART_END from CURRENT_PART_SIZE
      else
         CREATE_CURRENT_PART=1
			
         # The first partition on the drive should start at 0
         if [ ${CURRENT_PART} -eq 1 ]; then
            CURRENT_PART_START=0
		
         # Or if this partition is # 5 then this partition needs to start at the beginning 
         # of the extended partition
         elif [ ${CURRENT_PART} -eq 5 ]; then
            if [ $(grep "^[1-4]:" ${CURRENT_TABLE} | grep -c "extended") -ne 1 ]; then
               echo "Error: there are more than 4 partitions on this drive, but more or less than 1 extended partition"
               rm -rf /tmp/partition_table*
               return 1
            else
               EXTENDED_PART_START="$(grep "^[1-4]:" ${CURRENT_TABLE} | grep "extended" | cut -d ":" -f2 | cut -d "-" -f1)"
               CURRENT_PART_START="${EXTENDED_PART_START}"
            fi
            
         # Otherwise, we should start the partition from the end of the previous partition
         else
            # Set the CURRENT_PART_START point to the end of the previous partition (PREVIOUS_PART_END)
            PREVIOUS_PART_END="$(cat ${CURRENT_TABLE} | grep "^$(expr ${CURRENT_PART} - 1):" | cut -d ":" -f2 | cut -d "-" -f2)"
            if [ "${PREVIOUS_PART_END}" == "" ]; then
               echo "Error: end point for drive ${CURRENT_DRIVE} partition $(expr ${CURRENT_PART} - 1) is not set"
               rm -rf /tmp/partition_table*
               return 1
            fi
            CURRENT_PART_START="${PREVIOUS_PART_END}"
         fi

	 # Set the partitions that we'll be working with, either primary
	 # or logical.
	 if [ "${CURRENT_PART}" -le 4 ]; then
	    WORKING_PARTS="[1-4]"
	 else
	    WORKING_PARTS="[^1-4]"
	 fi

         # If the CURRENT_PART_SIZE == @, then set CURRENT_PART_END to CURRENT_DRIVE_SIZE
         if [ "${CURRENT_PART_SIZE}" == "@" ]; then
            
            # If there is a partition defined after the current partition, set CURRENT_PART_END to the NEXT_PART_START
            if [ "$(grep "^$(expr ${CURRENT_PART} + 1):" ${CURRENT_TABLE}.unprocessed)" != "" ] && [ $(echo "$(expr ${CURRENT_PART} + 1)" | grep -c ${WORKING_PARTS}) -eq 1 ]; then
		
               # If the partition is not going to be changed, we can get the start of that partition from parted
               if [ "$(grep "^$(expr ${CURRENT_PART} + 1):" ${CURRENT_TABLE}.unprocessed | cut -d ":" -f2)" == "" ]; then
                  if [ "$(parted -s ${CURRENT_DRIVE} print | grep "^$(expr ${CURRENT_PART} + 1)")" == "" ]; then
                     echo "Error: you wanted to keep drive ${CURRENT_DRIVE} partition ${CURRENT_PART} but it does not exist"
                     rm -rf /tmp/partition_table*
                     return 1
                  else
                     NEXT_PART_START=$(parted -s ${CURRENT_DRIVE} print | grep "^$(expr ${CURRENT_PART} + 1)" | awk -F " " '{ print $2 }')
                  fi
                  CURRENT_PART_END=${NEXT_PART_START}
	  
               # If the partition IS going to be created, we'll have to try to guestimate the location of NEXT_PART_START
               elif [ "$(grep "^$(expr ${CURRENT_PART} + 1):" ${CURRENT_TABLE}.unprocessed | cut -d ":" -f2)" != "" ]; then

                  # Initialize the counter variable
                  MB_TO_END_OF_DRIVE=0
                  while read part; do

		     # Make sure that $part is in the set of parts we are
		     # working with, i.e., primary or logical.
		     if [ $(echo ${part} | cut -d ":" -f1 | grep -c ${WORKING_PARTS}) -eq 0 ]; then
		        continue
		     fi
		     
                     # A drive cannot have more than one @ as the size, otherwise, we can't generate the proper size
                     if [ $(echo ${part} | cut -d ":" -f1) -gt ${CURRENT_PART} ] && [ "$(echo ${part} | cut -d ":" -f2)" == "@" ]; then
                        echo "Error: more than one partition with size set to @ (cannot determine correct size)"
                        rm -rf /tmp/partition_table*
                        return 1
						
                     # However, if there is only one @, then we can generate the proper size
                     elif [ $(echo ${part} | cut -d ":" -f1) -gt ${CURRENT_PART} ] && [ "$(echo ${part} | cut -d ":" -f2)" != "@" ]; then
                        if [ $(echo ${part} | cut -d ":" -f2 | grep -c "%") -eq 1 ]; then
                           PERCENT=$(echo "$(echo ${part} | cut -d ":" -f2)" | sed -n "s/\(.*\).$/\1/p")
                           part_size="$(echo "(${PERCENT} * ${CURRENT_DRIVE_SIZE}) / 100" | bc)"
                        elif [ $(echo ${part} | cut -d ":" -f2 | grep -c "M") -eq 1 ]; then
                           part_size="$(echo "$(echo ${part} | cut -d ":" -f2)" | sed -n "s/\(.*\).$/\1/p")"
                        fi
                        MB_TO_END_OF_DRIVE=$(echo ${MB_TO_END_OF_DRIVE} + ${part_size} | bc)
                     fi
                  done < ${CURRENT_TABLE}.unprocessed
                  NEXT_PART_START=$(echo "${CURRENT_DRIVE_SIZE} - ${MB_TO_END_OF_DRIVE}" | bc)
                  CURRENT_PART_END=${NEXT_PART_START}
               fi 
            # Otherwise, fill this partition to the end of the drive
            else
               CURRENT_PART_END="${CURRENT_DRIVE_SIZE}"
            fi
            
         # If the CURRENT_PART_SIZE != @, then calculate its end by adding the size to the start point
         elif [ "${CURRENT_PART_SIZE}" != "" ]; then
            CURRENT_PART_END="$(echo "${CURRENT_PART_START} + ${CURRENT_PART_SIZE}" | bc)"
            
            # If the end of this partition is beyond the edge of the drive, give an error
            if [ $(echo "${CURRENT_PART_END} > ${CURRENT_DRIVE_SIZE}" | bc) -ne 0 ]; then
               echo "Error: end point for partition ${CURRENT_PART} is larger than drive ${CURRENT_DRIVE}"
               rm -rf /tmp/partition_table*
               return 1
            fi
         fi
      fi
      # Echo a line to this table
      echo "${CURRENT_PART}:${CURRENT_PART_START}-${CURRENT_PART_END}:${CURRENT_PART_TYPE}:${CREATE_CURRENT_PART}" >> ${CURRENT_TABLE}
   done < ${CURRENT_TABLE}.unprocessed
   rm -f ${CURRENT_TABLE}.unprocessed
   return 0
   }
   
   # Error Check partition tables
   partition_table_error_check() {
   
   # Get list of partition tables
   ls --color=none /tmp/partition_table/-dev-* > /tmp/partition_table_list
   if [ $? -ne 0 ]; then
      echo "Error: you did not set up any drives"
      rm -rf /tmp/partition_table*
      return 1
   fi
   
   # Loop for each drive
   while read part_table ; do
      DRIVE=$(echo ${part_table} | sed "s/\/tmp\/partition_table\/\(.*\)/\1/" | sed -n "s/-/\//gp")
      
      # If the drive does not exist on the system, error out
      if [ ! -e ${DRIVE} ]; then
         echo "Error: Drive ${DRIVE} does not exist on this system"
         rm -rf /tmp/partition_table*
         return 1
      fi
      
      DRIVE_SIZE=$(parted -s ${DRIVE} print | grep "Disk geometry for" | cut -d " " -f5 | cut -d "-" -f2)
      while read part_record ; do
         PART_NUMBER=$(echo ${part_record} | cut -d ":" -f1)
         PART_START=$(echo ${part_record} | cut -d ":" -f2 | cut -d "-" -f1)
         PART_END=$(echo ${part_record} | cut -d ":" -f2 | cut -d "-" -f2)
         PART_TYPE=$(echo ${part_record} | cut -d ":" -f3)
         CREATE=$(echo ${part_record} | cut -d ":" -f4)
      
         # Make sure that the partition starts at the right place
         if [ ${PART_NUMBER} -eq 1 ]; then
            if [ $(echo "${PART_START} < 0" | bc) -ne 0 ] || [ $(echo "${PART_START} >= 0.5" | bc) -ne 0 ]; then
               echo "Error: Drive ${DRIVE} partition 1 does not start at the beginning of the drive"
               rm -rf /tmp/partition_table*
               return 1
            fi
         elif [ ${PART_NUMBER} -gt 1 ]; then
            PREVIOUS_PART_TYPE=$(cat ${part_table} | sed -n "s/^$(expr ${PART_NUMBER} - 1):.*:\(.*\):.*/\1/p")
            PREVIOUS_PART_END=$(cat ${part_table} | grep "^$(expr ${PART_NUMBER} - 1):" | cut -d ":" -f2 | cut -d "-" -f2)
            if [ $(echo "${PART_START} < ${PREVIOUS_PART_END}" | bc) -ne 0 ] && [ "${PREVIOUS_PART_TYPE}" != "extended" ]; then
               echo "Error: Drive ${DRIVE} partition $(expr ${PART_NUMBER} - 1) and partition ${PART_NUMBER} overlap"
               rm -rf /tmp/partition_table*
               return 1
            fi         
         fi
      
         # Make sure the partition isn't longer than the drive is
         if [ $(echo "${PART_END} > ${DRIVE_SIZE}" | bc) -ne 0 ]; then
            echo "Error: Drive ${DRIVE} partition ${PART_NUMBER} is longer than your drive"
            rm -rf /tmp/partition_table*
            return 1
         fi
       
         # Make sure the format type is valid
         if [ "${PART_TYPE}" != "" ]; then     
            case "${PART_TYPE}" in
               ext2) ;;
               ext3) ;;
               swap) ;;
               reiserfs) ;;
               xfs) ;;
               jfs) ;;
               extended) if [ ${PART_NUMBER} -gt 4 ]; then 
                            echo "Error: ${PART_TYPE} is not a valid partition type for partitions greater than 4"
                            rm -rf /tmp/partiton_table*
                            return 1
                         fi ;;
               *) echo "Error: ${PART_TYPE} is not a valid partition type" ; rm -rf /tmp/partiton_table* ; return 1 ;;
            esac
         fi
      
         # Make sure that there are only 0 and 1 for partition choice
         if [ "${CREATE}" != "0" ] && [ "${CREATE}" != "1" ]; then
            echo "Error: Invalid partition creation choice"
            rm -rf /tmp/partition_table*
            return 1
         fi
      done < ${part_table}
   
      # If there are more than four partitions on the drive...
      if [ $(grep -c ":" ${part_table}) -gt 4 ]; then
      
         # Make sure an extended partition exists in the first four partitions
         if [ $(grep "^[1-4]:.*" ${part_table} | grep -c "extended") -lt 1 ]; then
            echo "Error: There are more than 4 partitions, but no extended partition"
            rm -rf /tmp/partition_table*
            return 1
         fi
      
         # Make sure there is only one extended partition in the first four partitions
         if [ $(grep "^[1-4]:.*" ${part_table} | grep -c "extended") -gt 1 ]; then
            echo "Error: There is more than 1 extended partition"
            rm -rf /tmp/partition_table*
            return 1
         fi
      
         # Warn if extended partition is in the first 3 partitions
         if [ $(grep "^[1-3]:.*" ${part_table} | grep -c "extended") -gt 0 ]; then
            echo "Warning: The extended partition is usually partition 4"
         fi

         # Make sure the extended partition can hold the other partitions (above 4)
         EXTENDED_PART_START=$(head -n 4 ${part_table} | grep "extended" | cut -d ":" -f2 | cut -d "-" -f1)
         EXTENDED_PART_END=$(head -n 4 ${part_table} | grep "extended" | cut -d ":" -f2 | cut -d "-" -f2)
         grep -v "^[1-4]:.*" ${part_table} > /tmp/logical_part_table
         while read logical_record ; do
            LOGICAL_PART_START=$(echo ${logical_record} | cut -d ":" -f2 | cut -d "-" -f1)
            LOGICAL_PART_END=$(echo ${logical_record} | cut -d ":" -f2 | cut -d "-" -f2)
            LOGICAL_PART_NUMBER=$(echo ${logical_record} | cut -d ":" -f1)
            if [ $(echo "${LOGICAL_PART_START} < ${EXTENDED_PART_START}" | bc) -ne 0 ] || [ $(echo "${LOGICAL_PART_END} > ${EXTENDED_PART_END}" | bc) -ne 0 ]; then
               echo "Error: Drive ${DRIVE} partition ${PART_NUMBER} is a logical partition, but does not fit in the extended partition"
               rm -f /tmp/logical_part_table
               rm -rf /tmp/partition_table*
               return 1
            fi
         done < /tmp/logical_part_table
		 
         # Make sure that, if the extended partition is going to be created, 
         # that the logical partitions are also going to be created
         if [ "$(grep -v "^[1-4]:.*" ${part_table} | grep "extended" | cut -d ":" -f4)" == "1" ]; then
            while read logical_record ; do
               if [ $(echo ${logical_record} | cut -d ":" -f4) -ne 1 ]; then
                  echo "Error: You are creating a new extended partition, but you want to save a logical partition"
                  rm -f /tmp/logical_part_table
                  rm -rf /tmp/partition_table*
		  return 1
               fi
            done < /tmp/logical_part_table
         fi
         rm -f /tmp/logical_part_table
      fi
   done < /tmp/partition_table_list
   return 0
   }

   create_partitions() {
   while read drive_partition_table ; do
      DRIVE=$(echo ${drive_partition_table} | sed -n "s/\/tmp\/partition_table\/\(.*\)/\1/p" | sed -n "s/-/\//gp")
      # delete all existing partitions that are no longer needed
      parted -s $DRIVE print | grep "^[0-9]" > /tmp/temp_current_table
      while read current_record ; do
	  CUR_PART_NUMBER="$(echo "$current_record" | awk -F " " '{ print $1 }')"
	  found="0"
	  while read partition_record ; do
	      PART_NUMBER=$(echo ${partition_record} | cut -d ":" -f1)
	      if [ "${CUR_PART_NUMBER}" == "${PART_NUMBER}" ]; then
		  found="1"
		  CREATE_PARTITION=$(echo ${partition_record} | cut -d ":" -f4)
		  if [ "$(parted -s ${DRIVE} print | grep "^${PART_NUMBER}")" != "" ] && [ "${CREATE_PARTITION}" -ne "0" ] ; then
		      parted -s ${DRIVE} rm ${PART_NUMBER}
		  fi
	      fi
	  done < ${drive_partition_table}
	  if [ "${found}" == "0" ]; then
	      parted -s ${DRIVE} rm ${CUR_PART_NUMBER}
	  fi
      done < /tmp/temp_current_table
      rm -f /tmp/temp_current_table
      
      while read partition_record ; do
         PART_NUMBER=$(echo ${partition_record} | cut -d ":" -f1)
         CREATE_PARTITION=$(echo ${partition_record} | cut -d ":" -f4)
         if [ ${CREATE_PARTITION} -eq 0 ]; then
            if [ "$(parted -s ${DRIVE} print | grep "^${PART_NUMBER}")" == "" ]; then
               echo "Error: You wanted to keep drive ${DRIVE} partition ${PART_NUMBER} but it does not exist"
               rm -rf /tmp/partition_table*
               return 1
            fi
         elif [ ${CREATE_PARTITION} -eq 1 ]; then
            PART_START="$(echo ${partition_record} | cut -d ":" -f2 | cut -d "-" -f1)"
            PART_END="$(echo ${partition_record} | cut -d ":" -f2 | cut -d "-" -f2)"
            PART_TYPE="$(echo ${partition_record} | cut -d ":" -f3)"
            
            # If the partition to be written is a primary partition
            if [ ${PART_NUMBER} -le 4 ]; then
               
               # If the partition is a swap partition
               if [ "${PART_TYPE}" == "swap" ]; then
                  parted -s ${DRIVE} mkpart primary linux-swap ${PART_START} ${PART_END}
                  if [ $? -ne 0 ]; then
		     rm -rf /tmp/partition_table*
		     return 1
                  fi
                  
               # If the partition is an extended partition
               elif [ "${PART_TYPE}" == "extended" ]; then
                  parted -s ${DRIVE} mkpart extended ${PART_START} ${PART_END} 
                  if [ $? -ne 0 ]; then
		     rm -rf /tmp/partition_table*
		     return 1
                  fi
                  
               # If the partition is a normal partition
               else
                  parted -s ${DRIVE} mkpart primary ${PART_START} ${PART_END}
                  if [ $? -ne 0 ]; then
		     rm -rf /tmp/partition_table*
		     return 1
                  fi
               fi
            
            # If the partition to be written is a logical partition
            else
               
               # If the partition is a swap partition
               if [ "${PART_TYPE}" == "swap" ]; then
                  parted -s ${DRIVE} mkpart logical linux-swap ${PART_START} ${PART_END}
                  if [ $? -ne 0 ]; then
		     rm -rf /tmp/partition_table*
		     return 1
                  fi
               
               # If the partition is a normal partition
               else
                  parted -s ${DRIVE} mkpart logical ${PART_START} ${PART_END}
                  if [ $? -ne 0 ]; then
		     rm -rf /tmp/partition_table*
		     return 1
                  fi
               fi
            fi
         fi			
      done < ${drive_partition_table}
   done < /tmp/partition_table_list
   rm -rf /tmp/partition_table*
   return 0
   }
   
#--------------#
# Partitioning #
#--------------#

# A sample name of a partition table
# /tmp/partition_table/-dev-hda:
# The partition table lines should look like this:
# part#:partition range (in MB):type:create partition?
# 1:0-64:ext3:1
# 2:64-576:swap:1
# 3:576-15576:reiserfs:0
# 4:15576-45576:extended:1
# 5:15576-25576:jfs:1
# 6:25576-45576:xfs:1

# Remove any old partition tables
rm -rf /tmp/partition_table*
mkdir /tmp/partition_table

# Generate parition tables
for (( i=0 ; i < ${#PARTITION[@]} ; i++ )); do
   
   # If the partition is NOT an NFS paritition and...
   # if a table for this drive does not exist, then generate one
   if [ "$(echo "${PARTITION[${i}]}" | grep ":")" == "" ] && \
      [ ! -f /tmp/partition_table/$(get_drive_and_part "${PARTITION[${i}]}" \
      | cut -d " " -f1 | sed -n "s/\//-/gp") ]
   then
      create_partition_table "${PARTITION[${i}]}" || return 1
   fi
done

# Error check the partition tables
partition_table_error_check || return 1

# Create partitions
create_partitions || return 1

#-----------#
# Formating #
#-----------#
# Loop to check all the partitions in the config file
for (( i=0 ; i < ${#PARTITION[@]} ; i++ )); do

   # If the partition is linux or linux-swap type and the type IS set, then format it accordingly
   if [ "${PARTITION_TYPE[${i}]}" != "" ]; then
      case "${PARTITION_TYPE[${i}]}" in
         ext2) mke2fs ${PARTITION[${i}]} || return 1;;
         ext3) mke2fs -j ${PARTITION[${i}]} || return 1;;
         reiserfs) yes | mkreiserfs ${PARTITION[${i}]} || return 1;;
         xfs) mkfs.xfs ${PARTITION[${i}]} || return 1;;
         jfs) mkfs.jfs ${PARTITION[${i}]} || return 1;;
         swap) mkswap ${PARTITION[${i}]} || return 1;;
	 extended) ;;
         nfs) ;;
         *) echo "Error: ${PARTITION_TYPE[${i}]} is not a valid format type." ; return 1;;
      esac
   fi
done

#----------#
# Mounting #
#----------#
rm -f /tmp/mounting_table*
for (( i=0 ; i < ${#PARTITION[@]} ; i++ )); do

   # If partition is a swap type swapon it.
   if [ "${PARTITION_TYPE[${i}]}" == "swap" ]; then
      swapon ${PARTITION[${i}]}
      if [ $? -ne 0 ]; then
         rm -f /tmp/mounting_table.tmp
         return 1
      fi

   # Otherwise, add the partition to our table
   elif [ "${PARTITION_TYPE[${i}]}" != "extended" ] && [ "${PARTITION_MOUNT[${i}]}" != "" ]; then
      echo "${PARTITION_MOUNT[${i}]}@${PARTITION[${i}]}" >> /tmp/mounting_table.tmp
   fi
done

# Sort the mounts (in mounting order)
# We need to first remove the @ and then add it back after sorting
cat /tmp/mounting_table.tmp | sed 's/@/ /g' | sort | sed 's/ /@/g' > /tmp/mounting_table
rm -f /tmp/mounting_table.tmp

# Mounting loop
while read line ; do
   # If the mount point doesn't exist, create it
   if [ ! -d /mnt/gentoo$(echo $line | cut -d "@" -f1) ]; then
      mkdir -p /mnt/gentoo$(echo $line | cut -d "@" -f1) 
      if [ $? -ne 0 ]; then
         echo "Error: mountpoint does not exist and could not be created"
         rm -f /tmp/mounting_table
         return 1
      fi
   fi

   # Both NFS and normal partitions are mounted the same way.
   mount $(echo $line | cut -d "@" -f2) /mnt/gentoo$(echo $line | cut -d "@" -f1)
   if [ $? -ne 0 ]; then
      echo "Error: could not mount $(echo $line | cut -d ":" -f2) to /mnt/gentoo$(echo $line | cut -d ":" -f1)"
      rm -f /tmp/mounting_table
      return 1
   fi
done < /tmp/mounting_table
rm -f /tmp/mounting_table
return 0
}
