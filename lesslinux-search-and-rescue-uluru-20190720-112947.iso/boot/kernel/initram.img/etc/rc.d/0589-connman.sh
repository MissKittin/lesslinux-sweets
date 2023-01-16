#!/static/bin/ash

#lesslinux provides connman

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH
LC_ALL=C
export LC_ALL

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/rc.defaults.override ] && . /etc/rc.defaults.override

# Start connman as network manager
case $1 in
    start)
	# FIXME: Also check for NetworkManager! 
	if wicd-cli --wireless -i ; then
		printf "$bold+++> Ignoring connection manager (connman) - wicd seems to be running $normal\n"
	else
		printf "$bold===> Starting connection manager (connman) $normal\n"
		[ "$security" = "smack" ] && \
			echo netmgr > /proc/self/attr/current
		connmand 
		wpa_supplicant -u -B 
	fi
    ;;
    stop)
	printf "$bold===> Stopping connection manager (connman) $normal\n"
	killall -9 connmand 
	killall -9 wpa_supplicant 
    ;;
esac
		
