#!/bin/bash
		
#lesslinux provides xpra
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
HOME=/root
export HOME

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

start_xpra=0
xpra_app=/usr/bin/xterm
[ -x /usr/bin/xfce4-terminal ] && xpra_app=/usr/bin/xfce4-terminal 

for i in ` cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline `
do
   case "$i" in
     xpra=*)
	xpra=`echo "$i" | awk -F '=' '{print $2}'`
	if [ "$xpra" -gt 0 ] ; then
	    start_xpra=1
	elif [ "$xpra" = true ] ; then
	    start_xpra=1
	elif echo "$xpra" | grep -q '^/' ; then
	    start_xpra=1
	    xpra_app="$xpra" 
	fi
     ;;
   esac
done   

case $1 in 
    start)
	if [ "$start_xpra" -gt 0 ] ; then
		printf "$bold===> Enable XPRA access $normal\n"
		xpra start :100 
		if [ -x "$xpra_app" ] ; then
			DISPLAY=:100 "$xpra_app" &
		fi
	fi
    ;;
    stop)
	xpra stop :100 
    ;;
esac

		
