#!/static/bin/ash

#lesslinux provides syslogd

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Start syslogd

case $1 in 
    start)
	printf "$bold===> Starting syslogd $normal \n"
	syslogd -l "$sysloglevel" -D &
    ;;
esac
#		
