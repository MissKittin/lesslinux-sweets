#!/static/bin/ash
		
#lesslinux provides rfkill
#lesslinux license BSD
#lesslinux description

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Checking rfkill $normal"
	[ -c /dev/rfkill ] && rfkill unblock all
    ;;
esac

# END		
