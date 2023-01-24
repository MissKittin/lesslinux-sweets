#!/static/bin/ash
	
#lesslinux provides debug-001
#lesslinux debug 5

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

now=`date '+%Y%M%d-%H%M%S' ` 

# Mount some initial filesystems
case $1 in
    start)
	echo -n "$now" > /var/run/lesslinux/startup_time
	mkdir -p /lesslinux/debug/${now}
	cat /proc/cmdline > /lesslinux/debug/${now}/${now}_cmdline.txt
	cat /proc/version > /lesslinux/debug/${now}/${now}_version.txt
	cat /proc/cpuinfo > /lesslinux/debug/${now}/${now}_cpuinfo.txt
	cat /proc/meminfo > /lesslinux/debug/${now}/${now}_meminfo.txt
	cat /proc/bus/pci/devices > /lesslinux/debug/${now}/${now}_pcidevices.txt
	cat /proc/devices > /lesslinux/debug/${now}/${now}_devicenodes.txt
	cat /proc/modules > /lesslinux/debug/${now}/${now}_modules.txt
	lsmod > /lesslinux/debug/${now}/${now}_modules2.txt
	cat /proc/mounts > /lesslinux/debug/${now}/${now}_mounts.txt
	dmesg > /lesslinux/debug/${now}/${now}_dmesg.txt
	cp /etc/lesslinux/updater/version.txt /lesslinux/debug/${now}/${now}_buildid.txt
	sleep 2
    ;;
esac
#		
