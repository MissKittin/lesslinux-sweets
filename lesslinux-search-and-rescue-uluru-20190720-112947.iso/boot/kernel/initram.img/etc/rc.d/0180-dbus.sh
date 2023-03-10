#!/static/bin/ash
	
#lesslinux provides dbus
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "${bold}===> Starting DBUS ${normal}\n"
	mountpoint -q /usr/var || mount -t tmpfs -o mode=0755 tmpfs /usr/var
	mkdir -p /usr/var/lib/dbus
	mkdir -p /usr/var/run/dbus
	mkdir -p /var/lib/dbus
	mkdir -p /var/run/dbus
	if [ '!' -f /var/lib/dbus/machine-id ] ; then
		dbus-uuidgen --ensure
	fi
	[ "$security" = "smack" ] && \
		echo netmgr > /proc/self/attr/current
	/usr/bin/dbus-daemon --config-file=/usr/share/dbus-1/system.conf
    ;;
    stop)
	true
        # echo "FIXME: properly stop dbus"
    ;;
esac

			
