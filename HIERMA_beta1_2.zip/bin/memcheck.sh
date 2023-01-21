#!/usr/bin/env bash
# Check system RAM for low memory, and prompt user to create a swapfile
# if it is too low. Memory is measured in megabytes.

minimum=96
totalpos=$(free -m | sed -n '1p' | sed 's/total.*/total/' | wc -c)
freemegs=$(free -m | grep 'Mem:' | cut -c -$totalpos | sed 's/Mem://;s/\s//g')
if [ $freemegs -lt $minimum ]; then
    # HIERMA needs to know if a swapfile is already active or something.
    if [ "$1" = "BOOTENV" ]; then
        dialog --title "Notice: Low Memory" --msgbox "You have less than ${minimum}MB of RAM installed in your system. Since you're booting from a live environment that runs entirely in RAM, HIERMA may effectively crash your system while trying to install your operating system.\n\nTo avoid this, a temporary swapfile can be created on your hard disk so $(uname) has some virtual memory to work with.\n\nTo create a swapfile, select \"Swapfile\" in the following dialog. Or, if you haven't formatted a partition yet, do that, and you will be prompted to create a swapfile." 15 70
    exit
    elif [ "$1" = "DISKUTIL" ]; then
        dialog --title "Notice: Low Memory" --yesno "You have less than ${minimum}MB of RAM installed in your system. Since you're booting from a live environment that runs entirely in RAM, HIERMA may effectively crash your system while trying to install your operating system.\n\nTo avoid this, a temporary swapfile can be created on your hard disk so $(uname) has some virtual memory to work with.\n\nDo you want to create a swapfile on the newly formatted partition now?" 15 70
        if [ $? != 0 ]; then
            exit 1
        else
            mypart="$($scriptdir/hierma_getparm.sh mypart)"
            basepart=$(basename $mypart)
            $scriptdir/hierma_swap.sh "/mnt/hierma_$basepart"
            exit
        fi
    fi
fi
