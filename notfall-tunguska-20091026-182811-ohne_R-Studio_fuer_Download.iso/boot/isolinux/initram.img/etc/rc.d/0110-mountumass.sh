#!/static/bin/ash
		
#lesslinux provides mountumass
#lesslinux patience
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
        if [ -f /var/run/lesslinux/cdfound ] ; then
	    printf "$bold===> Skip search for LESSLINUX USB/HDD $normal\n"
	else
	    printf "$bold===> Searching for LESSLINUX USB/HDD $normal\n"
	    [ "$usbsettle" -gt 1 ] && sleep $usbsettle && mdev -s
	    for i in ` seq $usbwait ` ; do
		parts=` fdisk -l | grep -E ' FAT| Linux' | awk '{ print $1}' `
		mkdir -p /lesslinux/cdrom
		for i in $parts ; do
		    mount -o "$hwmode" "$i" /lesslinux/cdrom
		    thisversion=` cat /etc/lesslinux/updater/version.txt `
		    thatversion=` cat /lesslinux/cdrom/version.txt `
		    if [ "$thisversion" = "$thatversion" ] ; then
			echo -n "$i" > /var/run/lesslinux/install_source
			touch /var/run/lesslinux/usbfound
			touch /var/run/lesslinux/cdfound
			exit 0
		    else
			umount /lesslinux/cdrom
		    fi
		done
		[ '!' -f /var/run/lesslinux/cdfound ] && sleep 5 && mdev -s
	    done
	fi
    ;;
esac

# The end	
