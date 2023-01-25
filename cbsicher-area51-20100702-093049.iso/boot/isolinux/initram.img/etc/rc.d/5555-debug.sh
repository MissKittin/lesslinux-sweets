#!/static/bin/ash
	
#lesslinux provides debug-555
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
	dmesg > ${debugdir}/${startup_time}/${now}_dmesg.txt
	hwinfo --all > ${debugdir}/${startup_time}/${now}_hwinfo.txt
	tar cvf ${debugdir}/${startup_time}/${now}_log.tar /var/log /usr/var/log /var/run/lesslinux
	( cd ${debugdir} ; zip -r ${startup_time}.zip ${startup_time} )
	sleep 2
    ;;
esac
#		
