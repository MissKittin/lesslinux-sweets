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
	cat /proc/mounts > ${debugdir}/${startup_time}/${now}_mounts.txt
	cat /proc/swaps > ${debugdir}/${startup_time}/${now}_swaps.txt
	cp /usr/var/log/Xorg.0.log ${debugdir}/${startup_time}/${now}_Xorg_0_log.txt
	cp /usr/var/log/Xorg.1.log ${debugdir}/${startup_time}/${now}_Xorg_1_log.txt
	Xorg -configure :3
	cp /usr/var/log/Xorg.3.log ${debugdir}/${startup_time}/${now}_Xorg_3_log.txt
	cp /xorg.conf.new ${debugdir}/${startup_time}/${now}_xorg_conf_new.txt
	dmesg > ${debugdir}/${startup_time}/${now}_dmesg.txt
	sleep 2
    ;;
esac
#		
