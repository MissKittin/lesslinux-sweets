#!/bin/bash

if [ "$(id -un)" != "root" ]; then
    >&2 echo "This utility must be run as root."
    #exit 1
fi

mypart="$($scriptdir/hierma_getparm.sh mypart)"
swap_path="$1"
if [ -z "$swap_path" ]; then
    swap_path="$($scriptdir/hierma_getparm.sh swap_path)"
fi

# Swap size specified in the database is measured in megabytes.
# I would just leave this at 64MB; it's plenty enough to fit in many
# hard drives while giving the system lots of breathing room for what it runs.
# If it turns out to be necessary, I can add a dialog to let the user
# change the swapfile size.

swap_size="$($scriptdir/hierma_getparm.sh swap_size)"
swap_blocks=$((swap_size*1024))

create_swap() {
    if [ ! -z "$swap_path" ]; then
        dialog --title "Creating Swapfile" --infobox "Creating a ${swap_size}MB swapfile... this may take a while." 3 60 0
        dd if=/dev/zero of="$swap_path/swapfile" bs=1024 count=$swap_blocks
        if [ $? != 0 ]; then
            dderror="$(dd if=/dev/zero of="$swap_path/swapfile" bs=1024 count=$swap_blocks 2>&1)"
            export DIALOGRC="$scriptdir/derror"
            dialog --title "ERROR: Unable to Create Swapfile" --msgbox "HIERMA was unable to create a temporary swapfile at $swap_path. dd returned:\n\n   $dderror\n\nMake sure the correct partition has been mounted, and try again." 9 75
            unset DIALOGRC
            # Empty variable so the user is prompted for a new path.
            swap_path=""
        else
            # These permissions are probably worthless on FAT filesystems but
            # I'll set them anyway.
            chown root:root "$swap_path/swapfile"
            chmod 0600 "$swap_path/swapfile"
            mkswap "$swap_path/swapfile"
            swapon "$swap_path/swapfile"
        fi
    fi # if empty, do absolutely nothing (protection against misusage)
}

# Automatically create and activate a swapfile at the specified path if it is
# specified in $1, otherwise ask the user for the path.

while (true); do
if [ -z "$swap_path" ]; then
    swap_path="$(dialog --title 'Select Swap Path' --dselect /mnt 12 50)"
    if [ $? != 0 ]; then
        exit 1
    else
        create_swap
        exit
    fi    
else
    create_swap
    exit
fi
done
