#!/bin/bash
		
#lesslinux provides glib
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Preparing glib $normal\n"
	if cat /proc/mounts | grep -q 'usr/share/glib-2.0/schemas/gschemas.compiled' ; then
		exit 1
	fi
	mkdir -p /var/lesslinux/glib-2.0/schemas
	glib-compile-schemas --targetdir=/var/lesslinux/glib-2.0/schemas /usr/share/glib-2.0/schemas
	mount --bind /var/lesslinux/glib-2.0/schemas/gschemas.compiled /usr/share/glib-2.0/schemas/gschemas.compiled
    ;;
    stop)
	printf "$bold===> Removing glib preparations\n"
	umount /usr/share/glib-2.0/schemas/gschemas.compiled
	if cat /proc/mounts | grep -q 'usr/share/glib-2.0/schemas/gschemas.compiled' ; then
		exit 1
	else
		rm /var/lesslinux/glib-2.0/schemas/gschemas.compiled
	fi
    ;;
esac
		
