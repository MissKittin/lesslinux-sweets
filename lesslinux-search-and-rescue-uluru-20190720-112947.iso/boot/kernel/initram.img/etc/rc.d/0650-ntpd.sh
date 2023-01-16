#!/static/bin/ash
		
#lesslinux provides ntpd
#lesslinux license BSD
#lesslinux description

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Setting clock $normal"
	/static/sbin/ntpd -q -p ptbtime1.ptb.de
    ;;
esac

# END		
