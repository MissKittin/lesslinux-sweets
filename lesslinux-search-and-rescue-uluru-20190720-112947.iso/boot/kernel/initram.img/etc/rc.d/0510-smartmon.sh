#!/static/bin/ash
		
#lesslinux provides smartmon
#lesslinux license BSD
#lesslinux description
# Allow surfer to use gparted

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Enabling SMART $normal\n"
	for dev in /dev/sd[a-z] ; do
	    smartctl --smart=on --offlineauto=on --saveauto=on $dev > /dev/null 2>&1
	    smartctl --test=short $dev 
	done
    ;;
esac

		
