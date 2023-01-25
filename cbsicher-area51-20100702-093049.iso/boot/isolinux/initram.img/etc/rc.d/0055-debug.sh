#!/static/bin/ash
	
#lesslinux provides debug-005
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
	cat /proc/bus/pci/devices > /lesslinux/debug/${startup_time}/${now}_pcidevices.txt
	cat /proc/devices > /lesslinux/debug/${startup_time}/${now}_devicenodes.txt
	cat /proc/modules > /lesslinux/debug/${startup_time}/${now}_modules.txt
	lsmod > /lesslinux/debug/${startup_time}/${now}_modules2.txt
	cat /proc/mounts > /lesslinux/debug/${startup_time}/${now}_mounts.txt
	dmesg > /lesslinux/debug/${startup_time}/${now}_dmesg.txt
	sleep 2
    ;;
esac
#		
