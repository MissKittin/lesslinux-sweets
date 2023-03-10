#!/bin/bash
		
#lesslinux provides usbip
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

usbip=''

for i in ` cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline ` ; do
   case "$i" in
     usbip=*)
	usbip=`echo "$i" | awk -F '=' '{print $2}' | sed 's/|/ /g'` 
     ;;
   esac
done

case $1 in 
    start)
	if [ -n "$usbip" ] ; then
		printf "$bold===> Exporting usb-ip devices$normal\n"
		usbipd -D 
		for dev in $usbip ; do
			usbip bind -b $dev
			sleep 1
			usbip attach -r 127.0.0.1 -b $dev
			sleep 1 
			usbip detach -p 0
		done
	fi
    ;;
    stop)
	if [ -n "$usbip" ] ; then
		printf "$bold===> Unexporting usb-ip devices$normal\n"
		for dev in $usbip ; do
			usbip unbind -b $dev
		done
		killall usbipd
	fi
    ;;
esac


