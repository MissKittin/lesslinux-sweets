#!/static/bin/ash
	
#lesslinux provides udev
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "${bold}===> Starting UDEVD ${normal}\n"
	mkdir -p /run/udev
	echo > /proc/sys/kernel/hotplug
	[ "$security" = "smack" ] && \
		echo netmgr > /proc/self/attr/current
	[ -f /sbin/udevd     ] && /sbin/udevd --daemon
	[ -f /lib/udev/udevd ] && /lib/udev/udevd --daemon	
	[ -f /lib/udev/udev/udevd ] && /lib/udev/udev/udevd --daemon
	udevadm trigger --action=add    --type=subsystems
        udevadm trigger --action=add    --type=devices
        udevadm trigger --action=change --type=devices
	udevadm settle
    ;;
    stop)
	true
        # echo "FIXME: properly stop udev"
    ;;
esac

			
