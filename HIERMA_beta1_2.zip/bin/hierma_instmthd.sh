#!/usr/bin/env bash

instopt=$("$scriptdir/hierma_getparm.sh" instmthd)
src_path=$("$scriptdir/hierma_getparm.sh" src_path)

# Number of times HIERMA should attempt to reconnect to the remote server.
# Default is 3.
reconnects=${$("$scriptdir/hierma_getparm.sh" reconnects):3}

interactive_instmthd() {
while (true); do

if [ "$(id -un)" = "root" ]; then
    # Root user can mount/unmount devices and format disks.
    instopt=$(dialog --title 'Installation Options' --cancel-label "Back" --menu "Now you'll need to supply the path to your setup files. You can specify a local path or an FTP server in your network. If you need to use another CD or hard disk and it's not mounted, use the mount options below. You can also format a hard drive from here." 15 60 4 \
        'Local' 'Specify a local directory' \
        'FTP' 'Specify FTP location and credentials' \
        'Mount' 'Mount a device' \
        'Unmount' 'Unmount a device' 3>&1 1>&2 2>&3)
else
    # All other users can only specify paths they have access to.
    instopt=$(dialog --title 'Installation Options' --cancel-label "Back" --menu "Now you'll need to supply the path to your setup files. You can specify a local path or an FTP server in your network." 11 60 2 \
        'Local' 'Specify a local directory' \
        'FTP' 'Specify FTP location and credentials' 3>&1 1>&2 2>&3)
fi

if [ $? = 0 ]; then
	case $instopt in
	'Local')
		"$scriptdir/hierma_setparm.sh" instopt "local"
		"$scriptdir/hierma_pathsel.sh" LOCAL src_path
		if [ $? = 0 ]; then
			exit 0
		fi
		;;
	'FTP')
		"$scriptdir/hierma_setparm.sh" instopt "ftp"
        "$scriptdir/hierma_pathsel.sh" FTP src_path ftpserver ftpuser ftppass
		if [ $? = 0 ]; then
			exit 0
		fi
		;;
	'Mount') "$scriptdir/hierma_mount.sh" MOUNT ;;
	'Unmount') "$scriptdir/hierma_mount.sh" UMOUNT ;;
	esac
else
    exit 1
fi

done
}

if [ $EXPRESS = 1 ] && [ "$src_path" ]; then

case $instopt in

    local)
        ls "$src_path" 2>&1 /dev/null
        if [ $? != 0 ]; then
            lserr="$(ls "$src_path" 2>&1)"
            export DIALOGRC=derror
            dialog --title "ERROR: Cannot read from source" --msgbox "HIERMA cannot read from the source path. ls returned:\n\n     $lserr\n\nYou will need to assign a source path manually. Afterwards, HIERMA will continue with the unattended routines." 13 78
            unset DIALOGRC
            interactive_instmthd
        fi
        exit 0
    ;;
    ftp)
        dialog --msgbox "FTP selected, but not implemented." 5 50
        interactive_instmthd
    ;;

esac

else
    interactive_instmthd
fi


