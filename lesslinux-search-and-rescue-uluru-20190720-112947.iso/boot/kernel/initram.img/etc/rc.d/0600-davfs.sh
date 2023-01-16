#!/bin/bash
		
#lesslinux provides davfs
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    stop)
	davdirs=` cat /proc/mounts | grep '^http' | awk '{print $2}' ` 
	for d in $davdirs ; do
		umount $d
		mountpoint -q $d && umount -f $d
		if mountpoint -q $d ; then
			fuser -k $d
			umount $d
		fi
	done
    ;;
esac
		
