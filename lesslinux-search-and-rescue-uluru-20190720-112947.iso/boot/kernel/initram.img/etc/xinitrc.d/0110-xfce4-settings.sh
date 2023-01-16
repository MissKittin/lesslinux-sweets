#!/bin/bash
#lesslinux provides xfce4-settings

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
		
. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

x11vnc=''
conn=''
pass=''
parg=''

case $1 in start)
	 xfsettingsd 
	( for n in ` seq 5 ` ; do
		sleep 1
		xfsettingsd --replace 
	done ) &
	;;
esac

		
