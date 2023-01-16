#!/static/bin/ash
#lesslinux provides tz
#lesslinux license BSD
#lesslinux description
# Link the correct timezone

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	printf "$bold===> Linking timezone... $normal\n"
	if [ -n "$tz" ] && [ -f "/usr/share/zoneinfo/${tz}" ] ; then
	    cp -f /usr/share/zoneinfo/${tz} /etc/localtime
	else
	    echo "Determining timezone failed. Keep UTC."
	fi
    ;;
esac
	
		
