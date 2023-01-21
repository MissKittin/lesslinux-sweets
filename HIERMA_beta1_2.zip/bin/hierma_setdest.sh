#!/usr/bin/env bash

isetpath() {

while (true); do
if [ "$(id -un)" = "root" ]; then
dest_choice=$(dialog --title 'Set Destination Path' --cancel-label 'Back' --menu "To get started, HIERMA needs to know where you're installing your operating system to. Note that hard disks are not immediately available to $(uname) on boot, so you'll need to select \"Mount\" or \"Format\" before specifying the path." 14 75 4 \
    'Path' 'Specify the destination path' \
    'Mount' 'Mount a device' \
    'Unmount' 'Unmount a device' \
    'Format' 'Format a hard disk' 3>&1 1>&2 2>&3)
destexit=$?
else
dest_choice=$(dialog --title 'Set Destination Path' --cancel-label 'Back' --menu "To get started, HIERMA needs to know where you're installing your operating system to. If you need to mount or format a hard disk, you must either run HIERMA as root or open a root shell and execute the commands required to do so yourself." 11 75 1 \
    'Path' 'Specify the destination path' 3>&1 1>&2 2>&3)
destexit=$?
fi
if [ $destexit = 0 ]; then
    case "$dest_choice" in
        'Path') # Not using pathsel, as this needs to be handled differently.

            mypart="$("$scriptdir/hierma_getparm.sh" mypart)"
            lastdir="$(cat lastdir 2> /dev/null)"
            if [ -z "$lastdir" ]; then
                default_dest="./HIERMA"
            else
                default_dest="$lastdir/HIERMA"
            fi

            dest_path="$(dialog --title 'Set Destination Path' --dselect "$default_dest" 12 50 3>&1 1>&2 2>&3)"
            # Ask user to create the directory if it does not exist.
            if [ $? = 0 ]; then
                # note: convert this to a case later...
                ls $dest_path > /dev/null 2>&1
                mdexit=$?
                if [ $mdexit = 2 ]; then
                    dialog --title "Nonexistent Destination" --yesno "The path\n\n    $dest_path\n\ndoes not exist. Do you want to create it?" 9 70
                    if [ $? = 0 ]; then
                        mkdir -p $dest_path
                        if [ $? = 0 ]; then
                            dest_path="$(echo "$dest_path" | sed 's|/$||')"
                            "$scriptdir/hierma_setparm.sh" dest_path "$dest_path"
                            exit
                        else
                            mderror=$(mkdir -p $dest_path 2>&1)
                            export DIALOGRC="$scriptdir/derror"
                            dialog --title "Could Not Create Destination" --msgbox "The destination directory could not be created. mkdir returned:\n\n    $mderror\n\nPlease choose a different directory." 10 70
                            unset DIALOGRC
                            unset mderror
                        fi
                    fi
                elif [ $mdexit = 0 ]; then
                    "$scriptdir/hierma_setparm.sh" dest_path "$dest_path"
                    exit
                fi
            fi

            ;;
        'Mount')
            "$scriptdir/hierma_mount.sh" MOUNTD
            if [ $? = 2 ]; then
                exit 0
            fi
            ;;
        'Unmount') "$scriptdir/hierma_mount.sh" UMOUNT ;;
        'Format')
            "$scriptdir/hierma_disk.sh"
            if [ $? = 2 ]; then
                # User formatted hard disk, move to the next step now.
                exit 0
            fi
            ;;
    esac
else
    exit 1
fi
done

}


if [ $EXPRESS = 1 ]; then

    # The script needs to get the device to mount and the destination path
    # from your database. If the destination cannot be set, the interactive
    # dialog will be displayed.

    # Need to know if a disk will be formatted automatically in database too...

    echo placeholder

else

    isetpath

fi
