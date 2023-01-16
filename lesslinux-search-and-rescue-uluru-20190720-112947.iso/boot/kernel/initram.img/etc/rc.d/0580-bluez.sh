#!/bin/bash
		
#lesslinux provides bluez
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	/usr/sbin/bluetoothd  & 
    ;;
    stop)
	killall -s SIGTERM bluetoothd 
    ;;
esac


