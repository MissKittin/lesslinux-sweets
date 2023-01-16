#!/static/bin/ash
	
#lesslinux provides debug-050
#lesslinux debug 5

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

now=`date '+%Y%M%d-%H%M%S' ` 

case $1 in
    start)
	sleep 10
	startup_time=` cat /var/run/lesslinux/startup_time `
	debugdir=/lesslinux/debug
	if [ -d /lesslinux/cdrom/debug ] && touch /lesslinux/cdrom/debug/is_writable ; then
	    debugdir=/lesslinux/cdrom/debug
	elif [ -d /lesslinux/debug_device/debug ] ; then
	    debugdir=/lesslinux/debug_device/debug
	fi
	cat /proc/bus/pci/devices > ${debugdir}/${startup_time}/${now}_pcidevices.txt
	cat /proc/devices > ${debugdir}/${startup_time}/${now}_devicenodes.txt
	cat /proc/modules > ${debugdir}/${startup_time}/${now}_modules.txt
	cat /proc/net/dev > ${debugdir}/${startup_time}/${now}_netdevices.txt
	cat /proc/net/wireless > ${debugdir}/${startup_time}/${now}_wireless.txt
	dmesg > ${debugdir}/${startup_time}/${now}_dmesg.txt
	ifconfig > ${debugdir}/${startup_time}/${now}_ifconfig.txt
	iwconfig > ${debugdir}/${startup_time}/${now}_iwconfig.txt
	sleep 2
    ;;
esac
#		
