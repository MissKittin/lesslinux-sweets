#!/static/bin/ash

#lesslinux provides wicd

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH
LC_ALL=C
export LC_ALL

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/rc.defaults.override ] && . /etc/rc.defaults.override

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
	#
	# WARNING: Setting the encryption key via boot command line is nearly as dangerous as
	# leaving the network open. We currently use this function in an internet cafe, where 
	# all traffic is directed through a proxy.
	#
	# wlan=|essid|method|key| eg. wlan=|mynet|wpa|1234567890|
	#
	if [ -n "$wlan" ] ; then
		essid=` echo "$wlan" | awk -F '|' '{print $2}' `
		enctype=` echo "$wlan" | awk -F '|' '{print $3}' `
		enckey=` echo "$wlan" | awk -F '|' '{print $4}' `
		sleep 5
		wicd-cli --wireless -S
		netnum=` wicd-cli --wireless -l | grep -E '\s'"$essid"'$' | awk '{print $1}' ` 
		if [ -n "$enctype" ] ; then
			wicd-cli --wireless -n "$netnum" -p encryption -s True
			wicd-cli --wireless -n "$netnum" -p enctype -s "$enctype"
			wicd-cli --wireless -n "$netnum" -p encryption_method -s "$enctype"
			wicd-cli --wireless -n "$netnum" -p key -s "$enckey"
		else
			wicd-cli --wireless -n "$netnum" -p encryption -s False
		fi
		# wicd-cli --wireless -n "$netnum" -x
		wicd-cli --wireless -n "$netnum" -c
	fi
    ;;
esac
		
