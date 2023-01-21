#!/usr/bin/env bash
mntopt="$1"

mount_error() {
    mnterror="$(mount "$mountdev" "/mnt/hierma_$basedev" 2>&1)"
    export DIALOGRC="$scriptdir/derror"
    dialog --title "ERROR: Mount Failed" --msgbox "The mount operation failed. mount returned:\n\n    $mnterror\n\nCheck there is a medium in the device or it exists, and try again." 11 78
    unset DIALOGRC
}

mount_prompt() {
index=0
ls /dev/sd* > disklist.tmp

sed -n '/.*[0-9]/p' disklist.tmp > disklist2.tmp && mv disklist2.tmp disklist.tmp

# Remove devices already mounted from the list.
while read existdev; do
	sed "\|^$existdev|d" disklist.tmp > disklist2.tmp && mv disklist2.tmp disklist.tmp
done < udisklist.tmp

# Remove devices which don't register in fdisk.
while read thispart; do
    thatpart="$(fdisk -l | grep ^$thispart)"
    if [ "$thatpart" ]; then
        echo $thispart >> disklist2.tmp
    fi
done < disklist.tmp
mv disklist2.tmp disklist.tmp

# Always report removable drives.
ls /dev/sr* >> disklist.tmp
ls /dev/fd? >> disklist.tmp

menu[$index]="other"
index=$((index+1))
menu[$index]=""
index=$((index+1))
while read device; do
    menu[$index]="$device"
    index=$((index+1))

	# Second column displays the partition size.
	col2="$(fdisk -l $device | awk -F':' '{print $2}' | sed 's/,.*//g')"
    # Give some device files context for those unfamiliar with
    # the Unix directory structure.
    if [ "$(echo $device | grep '/dev/sr')" ]; then
        menu[$index]="CD-ROM $col2"
    elif [ "$(echo $device | grep '/dev/fd0')" ]; then
        menu[$index]="Floppy Drive A:"
    elif [ "$(echo $device | grep '/dev/fd1')" ]; then
        menu[$index]="Floppy Drive B:"
    else
        menu[$index]="$col2"
    fi
    index=$((index+1))
done < disklist.tmp
rm disklist.tmp

mountdev=$(dialog --title "Mount Device" --menu "Select a storage medium, or choose \"Other\" if it is not listed here." 19 40 10 "${menu[@]}" 3>&1 1>&2 2>&3)
}

if [ "$(id -un)" != "root" ]; then
    >&2 echo "This utility must be run as root."
    exit 1
fi

# Assemble the list of mounted disks regardless of which argument is used.
# This is so that certain listings in the MOUNT menu are excluded.
df | awk '{print $1}' | grep '^/dev/' > udisklist.tmp

case "$mntopt" in
'MOUNT')
    mount_prompt
    if [ $? = 0 ]; then
        if [ "$mountdev" = "other" ]; then
            mountdev=$(dialog --title "Mount Device" --inputbox "Enter the path to your device." 8 70 3>&1 1>&2 2>&3)
            if [ ! -z "$mountdev" ]; then
                basedev=$(basename $mountdev)
                mkdir /mnt/hierma_$basedev 2> /dev/null
                mount "$mountdev" "/mnt/hierma_$basedev" 2> /dev/null
                if [ $? != 0 ]; then
                    mount_error
                else
                    echo "/mnt/hierma_$basedev" > lastdir
                fi
            fi
        else
            basedev=$(basename $mountdev)
            mkdir "/mnt/hierma_$basedev" 2> /dev/null
            mount "$mountdev" "/mnt/hierma_$basedev" 2> /dev/null
            if [ $? != 0 ]; then
                mount_error
            else
                echo "/mnt/hierma_$basedev" > lastdir
            fi
        fi
    else
        # User hit Cancel.
        exit 1
    fi
    ;;
'UMOUNT')
    index=0
#        df | awk '{print $1}' | grep '^/dev/' > udisklist.tmp
    mountcol=$(df | sed -n 's/Mounted on//;1p' | wc -c)
    while read device; do
        menu[$index]="$device"
        index=$((index+1))
        menu[$index]="$(df $device | sed '1d' | cut -c $mountcol-)"
        index=$((index+1))
    done < udisklist.tmp
    umountdev=$(dialog --title "Unmount Device" --menu "Select a device to unmount. This is necessary if you need to swap between multiple removable disks." 19 60 10 "${menu[@]}" 3>&1 1>&2 2>&3)
    if [ $? = 0 ]; then
        umount $umountdev
    else
        # User hit Cancel.
        exit 1
    fi
    ;;
'MOUNTD')
    # Special mount option for hierma_setdest.sh.
    # A partition is automatically mounted to /mnt/hierma_dest.
    mount_prompt
    if [ $? = 0 ]; then
        if [ "$mountdev" = "other" ]; then
            mountdev=$(dialog --title "Mount Device" --inputbox "Enter the path to your device." 8 70 3>&1 1>&2 2>&3)
            if [ ! -z "$mountdev" ]; then
                mkdir /mnt/hierma_dest 2> /dev/null
                mount "$mountdev" "/mnt/hierma_dest" 2> /dev/null
                mkdir /mnt/hierma_dest/HIERMA 2> /dev/null
                "$scriptdir/hierma_setparm.sh" hierma_dest "/mnt/hierma_dest/HIERMA"
                dialog --title "Mount Device" --msgbox "The new partition has been mounted at /mnt/hierma_dest/HIERMA, and the destination path has been set to that automatically." 6 70
                if [ $? != 0 ]; then
                    mount_error
                fi
            fi
        else
            mkdir "/mnt/hierma_dest" 2> /dev/null
            mount "$mountdev" "/mnt/hierma_dest" 2> /dev/null
            mkdir /mnt/hierma_dest/HIERMA 2> /dev/null
            "$scriptdir/hierma_setparm.sh" hierma_dest "/mnt/hierma_dest/HIERMA"
            dialog --title "Mount Device" --msgbox "The new partition has been mounted at /mnt/hierma_dest/HIERMA, and the destination path has been set to that automatically." 6 70
            if [ $? != 0 ]; then
                mount_error
            fi
        fi
        exit 2
    else
        # User hit Cancel.
        exit 1
    fi
    ;;
esac
rm *.tmp 2> /dev/null
