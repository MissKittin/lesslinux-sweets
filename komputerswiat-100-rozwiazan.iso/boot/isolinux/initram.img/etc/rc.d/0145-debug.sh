#!/static/bin/ash
	
#lesslinux provides debug-025
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
	losetup > ${debugdir}/${startup_time}/${now}_losetup.txt
	lshw-static -xml -sanitize > ${debugdir}/${startup_time}/${now}_lshw.xml
	lshw-static -html -sanitize > ${debugdir}/${startup_time}/${now}_lshw.html
	lshw-static -short -sanitize > ${debugdir}/${startup_time}/${now}_lshw.txt
	lspci -nn > ${debugdir}/${startup_time}/${now}_lspci_nn.txt
	lspci -vv > ${debugdir}/${startup_time}/${now}_lspci_vv.txt
	lsusb -vv > ${debugdir}/${startup_time}/${now}_lsusb_vv.txt
	dmesg > ${debugdir}/${startup_time}/${now}_dmesg.txt
	sleep 2
    ;;
esac
#		
