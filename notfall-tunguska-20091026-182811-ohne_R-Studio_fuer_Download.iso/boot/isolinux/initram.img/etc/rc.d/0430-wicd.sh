#!/static/bin/ash

#lesslinux provides wicd

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH
LC_ALL=C
export LC_ALL

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Start wicd as network manager
case $1 in
    start)
	printf "$bold===> Starting Network daemon (wicd) $normal\n"
	mkdir /var/lib/wicd/configurations
	for i in 0 1 2 3 4 5 6 7 8 9 ; do
		for j in eth ath ra wlan ; do
			ifconfig ${j}${i} up > /dev/null 2>&1
		done
	done
	[ "$security" = "smack" ] && \
		echo netmgr > /proc/self/attr/current
	/usr/sbin/wicd
    ;;
esac
		
