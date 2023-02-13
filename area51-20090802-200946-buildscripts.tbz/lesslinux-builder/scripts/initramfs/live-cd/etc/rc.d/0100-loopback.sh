#!/static/bin/ash

PATH=/static/bin:/static/sbin:/bin:/sbin

. /etc/rc.conf
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Setting up loopback networking $normal \n"
	ifconfig lo 127.0.0.1 
    ;;
esac
