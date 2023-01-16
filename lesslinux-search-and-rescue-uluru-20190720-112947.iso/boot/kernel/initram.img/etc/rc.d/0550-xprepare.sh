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

# Allow Xorg modules to be skipped in case of defective drivers:
for i in ` cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline ` ; do
   case "$i" in
     skipxmods=*)
	skipxmods=`echo "$i" | awk -F '=' '{print $2}' | sed 's/|/ /g' ` 
     ;;
   esac
done

case $1 in
    start)
	printf "$bold===> Preparing start of X-Server $normal "
	# mountpoint -q /usr/var || mount -t tmpfs -o mode=0755 tmpfs /usr/var
	# mkdir /usr/var/log/
	# mkdir -p /usr/var/run/dbus
	mkdir -p /etc/dbus-1/session.d
	mountpoint -q /usr/share/X11/xkb/compiled || mount -t tmpfs -o mode=0755 tmpfs /usr/share/X11/xkb/compiled
	if fbset > /dev/null 2>&1 && cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline | grep -qv ' vga=' ; then
	    cp -f /etc/X11/xorg.conf.xorg /etc/X11/xorg.conf
	elif [ -n "$xorgconf" ] && [ -f "$xorgconf" ] ; then
	    cp -f  "$xorgconf" /etc/X11/xorg.conf
	    if [ -n "$xorgscreen" ] ; then 
	        touch /var/run/lesslinux/xconfgui_xorg
		touch /var/run/lesslinux/xconfgui_skip_monitor
	    fi
	else
	    cp -f /etc/X11/xorg.conf.xorg /etc/X11/xorg.conf
	fi
	for m in $skipxmods ; do
		if [ -f /usr/lib/xorg/modules/drivers/${m}.so ] ; then
			mount --bind /dev/null /usr/lib/xorg/modules/drivers/${m}.so
		fi
		if [ -f /usr/lib/xorg/modules/extensions/${m}.so ] ; then
			mount --bind /dev/null /usr/lib/xorg/modules/extensions/${m}.so
		fi
		if [ -f /usr/lib/xorg/modules/${m}.so ] ; then
			mount --bind /dev/null /usr/lib/xorg/modules/${m}.so
		fi
	done
	## FIXME: Make it possible to skip this Logitech fix
	## for mod in hid_logitech usbhid hid ; do
	##   /sbin/modprobe -r $mod
	## done
	## for mod in hid usbhid hid_logitech ; do
	##    /sbin/modprobe $mod
	## done
	## udevadm trigger
    ;;
    stop)
	umount /usr/var > /dev/null 2>&1
	umount /usr/share/X11/xkb/compiled > /dev/null 2>&1
    ;;
esac

# END		
