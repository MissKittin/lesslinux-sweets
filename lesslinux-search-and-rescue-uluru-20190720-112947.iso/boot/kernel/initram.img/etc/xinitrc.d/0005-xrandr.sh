#!/bin/bash
		
#lesslinux provides xrandr
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	if [ -n "$xrandr" ] ; then
		xrandr --size "$xrandr" 
	elif [ -z "$norotate" ] ; then
		aspect=` xrandr | grep '*' | head -n1 | awk '{print $1}' ` 
		width=` echo $aspect | awk -F 'x' '{print $1}' `
		height=` echo $aspect | awk -F 'x' '{print $2}' `
		if [ "$height" -gt "$width" ] ; then
			xrandr -o right 
		fi
	fi
    ;;
esac

		
