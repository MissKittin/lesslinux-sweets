#!/static/bin/ash
		
#lesslinux provides ff35prep
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

expiration=20101231
ffversion=3.5.3

case $1 in 
    start)
	printf "$bold===> Preparing Firefox 3.5.x $normal\n"
	if mountpoint -q /opt/firefox35/lib/firefox-$ffversion/lesslinux ; then
	    echo "tmpfs for firefox already mounted"
	else
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
	fi
    ;;
    stop)
	printf "$bold===> Unmounting Firefox 3.5.x overlay $normal\n"
	umount /opt/firefox35/lib/firefox-$ffversion/lesslinux > /dev/null 2>&1
	umount /etc/lesslinux/firefox > /dev/null 2>&1
    ;;
esac

		
