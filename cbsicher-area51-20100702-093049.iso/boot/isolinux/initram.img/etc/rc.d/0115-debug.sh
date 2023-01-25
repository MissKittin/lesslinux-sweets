#!/static/bin/ash
	
#lesslinux provides debug-015
#lesslinux debug 5

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

now=`date '+%Y%M%d-%H%M%S' ` 

case $1 in
    start)
	startup_time=` cat /var/run/lesslinux/startup_time `
        [ "$usbsettle" -gt 1 ] && sleep $usbsettle && mdev -s
	debugdir=/lesslinux/debug
	if [ -d /lesslinux/cdrom/debug ] && touch /lesslinux/cdrom/debug/is_writable ; then
	    debugdir=/lesslinux/cdrom/debug
	    touch /var/run/lesslinux/debug_device_found
	else
	    mkdir -p /lesslinux/debug_device
	    parts=` fdisk -l | grep ' FAT' | awk '{print $1}' ` 
	    parts="$parts "` ls /dev/sd[a-z] ` 
	    for i in $parts ; do
	        if [ '!' -f /var/run/lesslinux/debug_device_found ] ; then
		        printf "\n$bold---> Checking if its possible to save debug files on $i $normal \n"
			mount -o ro -t vfat $i /lesslinux/debug_device
			if [ -d /lesslinux/debug_device/debug ] ; then
			    printf "\n$bold---> Trying to save debug files on $i $normal \n"
			    mount -o remount,rw /lesslinux/debug_device
			    touch /var/run/lesslinux/debug_device_found
			    debugdir=/lesslinux/debug_device/debug
			else
			    umount /lesslinux/debug_device
			fi
		fi
	    done
	    [ -d /lesslinux/debug_device/debug ] || printf "\n$bold---> Debug files still in volatile memory $normal \n"
	fi
	if [ "$debugdir" '!=' "/lesslinux/debug" ] ; then
	    ( tar -C /lesslinux/debug -cvf - . | tar -C "$debugdir" -xf - )
	fi
	cat /proc/bus/pci/devices > ${debugdir}/${startup_time}/${now}_pcidevices.txt
	cat /proc/devices > ${debugdir}/${startup_time}/${now}_devicenodes.txt
	cat /proc/modules > ${debugdir}/${startup_time}/${now}_modules.txt
	lsmod > ${debugdir}/${startup_time}/${now}_modules2.txt
	cat /proc/mounts > ${debugdir}/${startup_time}/${now}_mounts.txt
	dmesg > ${debugdir}/${startup_time}/${now}_dmesg.txt
	sleep 2
    ;;
esac
#		
