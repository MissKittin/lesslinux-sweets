#!/static/bin/ash
	
#lesslinux provides iw

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH
LC_ALL=C
export LC_ALL

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/rc.defaults.override ] && . /etc/rc.defaults.override

# Set regulatory domain
case $1 in
    start)
	if [ -n "$regdom" ] ; then
		printf "$bold===> Setting regulatory domain to $regdom $normal\n"
		iw reg set "$regdom" 
	fi
    ;;
esac
#		
