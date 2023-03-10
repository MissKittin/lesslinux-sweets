#!/bin/bash
		
#lesslinux provides ethtool
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Searching sensors $normal\n"
	if sensors ; then
		echo '---> sensors works.'
	else
		yes yes | sensors-detect
	fi
    ;;
esac
		
