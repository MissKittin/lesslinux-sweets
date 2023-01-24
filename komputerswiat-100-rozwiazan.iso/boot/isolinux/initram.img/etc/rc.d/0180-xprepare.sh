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
	mount -t tmpfs -o mode=0755 tmpfs /usr/var
	mkdir /usr/var/log/
	mkdir -p /usr/var/run/dbus
	mount -t tmpfs -o mode=0755 tmpfs /usr/share/X11/xkb/compiled
	mkdir -p /etc/dbus-1/session.d/
	# FIXME: the choice of xorg.conf should be up to a boot parameter
	if [ -n "$xorgconf" ] && [ -f "$xorgconf" ] ; then
	    cp -f  "$xorgconf" /etc/X11/xorg.conf
	    if [ -n "$xorgscreen" ] ; then 
	        touch /var/run/lesslinux/xconfgui_xorg
		touch /var/run/lesslinux/xconfgui_skip_monitor
	    fi
	else
	    cp -f /etc/X11/xorg.conf.xorg /etc/X11/xorg.conf
	fi
	# FIXME: Make it possible to skip this Logitech fix
	for mod in hid_logitech usbhid hid ; do
	    /sbin/modprobe -r -v $mod
	done
	for mod in hid usbhid hid_logitech ; do
	    /sbin/modprobe -v $mod
	done
	printf "$success"
    ;;
    stop)
	umount /usr/var > /dev/null 2>&1
	umount /usr/share/X11/xkb/compiled > /dev/null 2>&1
    ;;
esac

# END		
