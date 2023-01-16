#!/bin/bash
		
#lesslinux provides xsetroot
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	for i in /etc/X11/xrdb.d/[0-9][0-9][0-9][0-9]-*.xrdb ; do
		script="$i"
		if [ -f ${HOME}/.config/xrdb.d/$( basename $i ) ] ; then
			script=${HOME}/.config/xrdb.d/$( basename $i )
		fi
		xrdb -merge $script
	done
    ;;
esac

		
