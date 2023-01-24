#!/static/bin/ash
		
#lesslinux provides ff35prep
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

expiration=20110228
ffversion=3.6.6

case $1 in 
    start)
	printf "$bold===> Preparing Firefox 3.6.x $normal\n"
	if mountpoint -q /opt/firefox35/lib/firefox-$ffversion/lesslinux ; then
	    echo "tmpfs for firefox already mounted"
	else
            [ "\$security" '!=' "smack" ] && cp /usr/bin/dbus-launch /static/bin/
	    mount -t tmpfs -o mode=0755,size=1m,nodev,nosuid,noexec tmpfs /opt/firefox35/lib/firefox-$ffversion/lesslinux
	    tar -C / -cf /tmp/.ff-$ffversion.tar /etc/lesslinux/firefox
	    mount -t tmpfs -o mode=0755,size=1m,nodev,nosuid,noexec tmpfs /etc/lesslinux/firefox
	    tar -C / -xf /tmp/.ff-$ffversion.tar
	    rm /tmp/.ff-$ffversion.tar
	    ln -sf /etc/lesslinux/firefox/firefox_common.cfg /opt/firefox35/lib/firefox-$ffversion/lesslinux/lesslinux.cfg 
	    idate=` date '+%Y%m%d' `
	    if [ "$idate" -gt "$expiration" ] ; then
	        cat /etc/lesslinux/firefox/prevent_xpi.cfg /etc/lesslinux/firefox/force_startpage.cfg > /etc/lesslinux/firefox/firefox_defaults.cfg
		ln -sf /etc/lesslinux/firefox/force_startpage.cfg /etc/lesslinux/firefox/firefox_allow_xpi.cfg
	    elif [ "$laxsudo" '=' 1 ] ; then	
	        ln -sf /etc/lesslinux/firefox/firefox_common.cfg /etc/lesslinux/firefox/firefox_allow_xpi.cfg
		ln -sf /etc/lesslinux/firefox/firefox_allow_xpi.cfg /etc/lesslinux/firefox/firefox_defaults.cfg
	    else
		ln -sf /etc/lesslinux/firefox/prevent_xpi.cfg /etc/lesslinux/firefox/firefox_defaults.cfg
		ln -sf /etc/lesslinux/firefox/firefox_common.cfg /etc/lesslinux/firefox/firefox_allow_xpi.cfg
	    fi
	    ln -sf /etc/lesslinux/firefox/firefox_defaults.cfg /opt/firefox35/lib/firefox-$ffversion/lesslinux/lesslinux.cfg
	    chown -R 1000:1000 /etc/lesslinux/firefox
	    # mount an overlay for plugins
	    mount -t tmpfs -o mode=0755,size=1m,nodev,nosuid tmpfs /opt/firefox35/lib/firefox-$ffversion/plugins
	    if [ "$skipflash" -gt 0 ] ; then
	        printf "$bold---> Skipping Flash Player $normal\n"
	    elif [ -f /etc/lesslinux/flashplugin ] ; then
		ln -s /usr/lib/browserplugins/` cat /etc/lesslinux/flashplugin ` /opt/firefox35/lib/firefox-$ffversion/plugins/
	    else
	        if [ "$laxsudo" -gt 0 ] ; then
	            if [ -f /usr/lib/browserplugins/libflashplayer.so ] ; then
		        ln -s /usr/lib/browserplugins/libflashplayer.so /opt/firefox35/lib/firefox-$ffversion/plugins/
		    elif [ -f /usr/lib/browserplugins/libgnashplugin.so ] ; then
		        ln -s /usr/lib/browserplugins/libgnashplugin.so /opt/firefox35/lib/firefox-$ffversion/plugins/
		    fi
	        else
		    if [ -f /usr/lib/browserplugins/libgnashplugin.so ] ; then
		        ln -s /usr/lib/browserplugins/libgnashplugin.so /opt/firefox35/lib/firefox-$ffversion/plugins/
		    elif [ -f /usr/lib/browserplugins/libflashplayer.so ] ; then
		        ln -s /usr/lib/browserplugins/libflashplayer.so /opt/firefox35/lib/firefox-$ffversion/plugins/
		    fi
		fi
	    fi
	fi
    ;;
    stop)
	printf "$bold===> Unmounting Firefox 3.6.x overlay $normal\n"
	umount /opt/firefox35/lib/firefox-$ffversion/lesslinux > /dev/null 2>&1
	umount /opt/firefox35/lib/firefox-$ffversion/plugins > /dev/null 2>&1
	umount /etc/lesslinux/firefox > /dev/null 2>&1
    ;;
esac

		
