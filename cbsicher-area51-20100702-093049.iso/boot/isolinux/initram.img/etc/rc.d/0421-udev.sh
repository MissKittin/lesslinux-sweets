#!/static/bin/ash
	
#lesslinux provides udev
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "${bold}===> Starting UDEVD ${normal}\n"
	[ "$security" = "smack" ] && \
		echo netmgr > /proc/self/attr/current
	/sbin/udevd --daemon 
    ;;
    stop)
	true
        # echo "FIXME: properly stop udev"
    ;;
esac

			
