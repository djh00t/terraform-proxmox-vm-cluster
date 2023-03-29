#!/bin/bash
###
### Script to find all disks that are not already formatted or mounted
###
# Create /etc/cloud/scripts/per-boot/01-storage.sh

function debug() {
    # echo $1 to screen if $DEBUG is set to 1
    if [ "$DEBUG" == "1" ]; then
        echo -e "| CORE\t\tDEBUG\t\t$1"
    fi
}

function help() {
    # Script arguments
    echo -e "Usage: $0 [OPTION]..."
    echo
    echo -e "  -d, --debug     Display debug information while executing"
    echo -e "  -h, --help      Display this help and exit"
}

# Script arguments
while [ "$1" != "" ]; do
    case $1 in
    -d | --debug)
        set DEBUG=1
        shift
        ;;
    -h | --help)
        help
        exit
        ;;
    *)
        set DEBUG=0
        shift
        ;;
    esac
done

debug "########################################################################"
debug "#                     STORAGE BOOT SCRIPT                              #"
debug "########################################################################"
# Make sure that /etc/cloud/scipts/per-boot exists
mkdir -p /etc/cloud/scripts/per-boot

# Create array of disks to ignore
IGNORE=(sda vda xvda floppy loop sr cdrom dvdrom fd)

# Find all disks except those in the ignore array
DISKS=$(lsblk -d -n -o NAME | grep -v -E "$(
    IFS="|"
    echo "${IGNORE[*]}"
)")

function get_next_mountid() {
    # Get the highest mountid from /data/mount[1-9]
    MOUNTID=$(ls -1 /data/mount[1-9] | sort -n | tail -n 1 | cut -d/ -f3 | cut -d"t" -f2)

    # Remove trailing colon from MOUNTID
    MOUNTID=${MOUNTID%?}

    # If MOUNTID is empty set it to 1
    if [ -z "$MOUNTID" ]; then
        MOUNTID=1
    else
        # If MOUNTID is not empty increment it by 1
        MOUNTID=$((MOUNTID + 1))
    fi

    # Check if MOUNTID is already in /etc/fstab
    if grep -q "mount$MOUNTID" /etc/fstab; then
        # If MOUNTID is already in /etc/fstab increment MOUNTID by 1 until it is no longer in /etc/fstab
        while grep -q "mount$MOUNTID" /etc/fstab; do
            MOUNTID=$((MOUNTID + 1))
        done
    fi

    # Return the next available mountid
    echo $MOUNTID
}

function do_format_disk() {
    # Set the disk to format
    DISK=$1
    MOUNTID=$2

    # Erase the disk first
    do_erase_disk $DISK

    # Format the disk
    echo -e "| STORAGE\tINFO\t\tFormatting disk:\t$DISK"
    mkfs.xfs -q -L mount$MOUNTID /dev/$DISK
    if $? -eq 0; then
        echo -e "| STORAGE\tOK\t\tDisk formatted:\t\t$DISK"
    else
        echo -e "| STORAGE\tFAIL\t\tDisk had a formatting error:\t$DISK"
        echo -e " --------------------------------------------------------------------------------------------"
        exit 1
    fi
}

function do_wipefs_disk() {
    # Set the disk to wipe
    DISK=$1
    # Wipe the disk
    echo -e "| STORAGE\tINFO\t\tWiping disk:\t\t$DISK"
    wipefs -a /dev/$DISK
    if $? -eq 0; then
        echo -e "| STORAGE\tOK\t\tDisk wiped:\t\t$DISK"
    else
        echo -e "| STORAGE\tFAIL\t\tDisk had a wipe error:\t\t$DISK"
        echo -e " --------------------------------------------------------------------------------------------"
        exit 1
    fi
}

# Print the disks found
echo -e " --------------------------------------------------------------------------------------------"
for disk in ${DISKS[@]}; do
    echo -e "| STORAGE\tINFO\t\tDisk found:\t\t$disk"
done

# Loop through the disks, if they aren't formatted remove all partitioning and format them using xfs
for DISK in $DISKS; do
    # Get the filesystem type of the disk
    FORMAT=$(lsblk -d -n -o FSTYPE /dev/$DISK)

    # Get the next available mountid
    MOUNTID=$(get_next_mountid)

    # If $FORMAT is empty, the disk is not formatted so set DISK_FMT to "0"
    if [ -z "$FORMAT" ]; then
        # Announce that the disk is not formatted
        echo -e "| STORAGE\tINFO\t\t$DISK is not formatted, wiping and formatting with xfs"

        # Format the disk
        do_format_disk $DISK $MOUNTID

    else
        # If $FORMAT is set to xfs, the disk is formatted with xfs so set DISK_FMT to "1"
        if [ "$FORMAT" == "xfs" ]; then
            # Announce that the disk is formatted with xfs
            echo -e "| STORAGE\tOK\t\tPre-formatted (xfs):\t$DISK"
        else
            # Announce that the disk is formatted with something other than xfs then erase the disk and format it with xfs
            echo -e "| STORAGE\tINFO\t\t$DISK is formatted with $FORMAT, erasing and formatting with xfs"

            # Format the disk
            do_format_disk $DISK $MOUNTID
        fi
    fi
done

# Loop through the disks, if they aren't mounted create a mount point and mount them
for DISK in $DISKS; do
    if [ -z "$(lsblk -d -n -o MOUNTPOINT /dev/$DISK)" ]; then
        # Announce that the disk is not mounted
        echo -e "| STORAGE\tFIX\t\t$DISK is not mounted"

        # Get the XFS label of the disk and set it as the mount point
        MOUNTPOINT=$(lsblk -d -n -o LABEL /dev/$DISK)

        # Make sure that the mount point exists in /data, if not create it
        if [ ! -d "/data/$MOUNTPOINT" ]; then
            echo -e "| STORAGE\tINFO\t\tCreating mount point /data/$MOUNTPOINT"
            mkdir -p /data/$MOUNTPOINT
            if $? -eq 0; then
                echo -e "| STORAGE\tOK\t\tMount point created:\t/data/$MOUNTPOINT"
            else
                echo -e "| STORAGE\tFAIL\t\tMount point had a creation error:\t/data/$MOUNTPOINT"
                echo -e " --------------------------------------------------------------------------------------------"
                exit 1
            fi
        fi

        # Make sure the mount point exists in /etc/fstab, if not add it
        if ! grep -q "/data/$MOUNTPOINT" /etc/fstab; then
            echo -e "| STORAGE\tINFO\t\tAdding mount point to /etc/fstab"
            echo -e "/dev/$DISK\t/data/$MOUNTPOINT\txfs\tnoatime,nodiratime,inode64,logbsize=256k\t0 0" >>/etc/fstab
            if $? -eq 0; then
                echo -e "| STORAGE\tOK\t\tMount point added to /etc/fstab"
            else
                echo -e "| STORAGE\tFAIL\t\tMount point had a /etc/fstab error"
                echo -e " --------------------------------------------------------------------------------------------"
                exit 1
            fi
        fi

        # Mount the disk
        echo -e "| STORAGE\tINFO\t\tMounting disk:\t\t$DISK"
        mount /data/$MOUNTPOINT
        if $? -eq 0; then
            echo -e "| STORAGE\tOK\t\tDisk mounted:\t\t$DISK"
        else
            echo -e "| STORAGE\tFAIL\t\tDisk had a mount error:\t\t$DISK"
            echo -e " --------------------------------------------------------------------------------------------"
            exit 1
        fi
    fi
done

echo -e " --------------------------------------------------------------------------------------------"
exit 0

# EOF
