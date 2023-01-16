#!/static/bin/ash
		
#lesslinux provides xprepare
#lesslinux license BSD
#lesslinux description
# Prepare some modules needed by Xserver

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Preparing start of X-Server	                         "
	# FIXME: Mount some overlay filesystems for xkbcomp and stuff here
	mount -t tmpfs -o mode=0755 tmpfs /usr/var
	mkdir /usr/var/log/
	mkdir -p /usr/var/run/dbus
	mount -t tmpfs -o mode=0755 tmpfs /usr/share/X11/xkb/compiled
	mkdir -p /etc/dbus-1/session.d/
	printf "$success"
    ;;
    stop)
	umount /usr/var > /dev/null 2>&1
	umount /usr/share/X11/xkb/compiled > /dev/null 2>&1
    ;;
esac

# END		
