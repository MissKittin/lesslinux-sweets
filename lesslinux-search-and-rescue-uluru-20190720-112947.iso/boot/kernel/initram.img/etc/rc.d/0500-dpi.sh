#!/bin/bash
		
#lesslinux provides dpi
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Prepare DPI settings $normal\n"
	mkdir -p /etc/X11/xrdb.d
	echo "Xft.dpi: ${dpi}" > /etc/X11/xrdb.d/0000-dpi.xrdb
    ;;
esac
		
