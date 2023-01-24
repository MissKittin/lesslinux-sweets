#!/static/bin/ash
	
#lesslinux provides mdev

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Mount some initial filesystems
case $1 in
    start)
	printf "$bold---> Using mdev to setup dynamic /dev                            "
        # mdev needs a shell at /bin/sh
	[ '!' -f /bin/sh ] && ln /static/bin/busybox /bin/sh
	echo /static/sbin/mdev > /proc/sys/kernel/hotplug
	sleep 1
        if mdev -s ; then
            printf "$success"
        else
            printf "$failed"
        fi
	chmod 0666 /dev/null
	chmod 0664 /dev/urandom
	chmod 0664 /dev/random
	chmod 0664 /dev/zero
    ;;
esac
#		
