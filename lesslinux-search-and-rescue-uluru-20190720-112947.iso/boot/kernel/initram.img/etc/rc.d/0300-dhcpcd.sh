#!/bin/bash
		
#lesslinux provides dhcpcd
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Starting dhcpcd on wired interfaces $normal\n"
	# Deferred loading of drivers might cause that no interface is available
	# sleep five seconds in this case!
	ifconfig eth0 || sleep 5
	for n in ` seq 0 9 ` ; do
		ifconfig eth${n} up > /dev/null 2>&1
		if ifconfig eth${n} > /dev/null 2>&1 ; then
			dhcpcd -p -b eth${n}
		fi
	done
    ;;
    stop)
	printf "$bold===> Stopping dhcpcd on wired interfaces $normal\n"
	for n in ` seq 0 9 ` ; do
		dhcpcd -x eth${i}
	done
	killall dhcpcd
    ;;
esac
		
