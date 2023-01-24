#!/static/bin/ash
	
#lesslinux provides debug-049
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
	Xorg -configure :3
	cp /usr/var/log/Xorg.3.log ${debugdir}/${startup_time}/${now}_Xorg_3_log.txt
	cp /xorg.conf.new ${debugdir}/${startup_time}/${now}_xorg_conf_new.txt
	sleep 2
    ;;
esac
#		
