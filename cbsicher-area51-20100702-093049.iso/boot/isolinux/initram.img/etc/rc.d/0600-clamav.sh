#!/static/bin/ash
		
#lesslinux provides clamav
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if mountpoint -q /opt/share/clamav ; then
	    printf "$bold===> Skipping ClamAV, already mounted $normal\n"
	else
	    printf "$bold===> Preparing ClamAV $normal\n"
	    rand=` dd if=/dev/urandom bs=1M count=1 | sha1sum | awk '{print $1}' `
	    tar -cf /tmp/clamav_${rand}.tar /opt/share/clamav
	    mount -o mode=755 -t tmpfs tmpfs /opt/share/clamav
	    tar -C / -xf /tmp/clamav_${rand}.tar
	    chown clamav:clamav /opt/share/clamav
	    rm /tmp/clamav_${rand}.tar
	    sed -i 's/^Example/\#Example/g' /etc/freshclam.conf
	    echo '' >> /etc/sudoers
	    echo '# added by /etc/rc.d/0600-clamav.sh' >> /etc/sudoers
	    if [ "$laxsudo" -gt 0 ] ; then
		echo 'surfer  ALL = NOPASSWD: /opt/bin/freshclam' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /opt/bin/clamscan' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /usr/share/lesslinux/avfrontend/virusfrontend' >> /etc/sudoers
	    else
		echo 'surfer  ALL = NOPASSWD: /opt/bin/freshclam' >> /etc/sudoers
		echo 'surfer  ALL = /opt/bin/clamscan' >> /etc/sudoers
		echo 'surfer  ALL = /usr/share/lesslinux/avfrontend/virusfrontend' >> /etc/sudoers
	    fi
	    /sbin/ldconfig -f /etc/ld.so.conf
	fi
    ;;
    stop)
	printf "$bold===> Unmounting ClamAV signatures $normal\n"
	if mountpoint -q /opt/share/clamav ; then
		fuser -km -9 /opt/share/clamav
	fi
	umount /opt/share/clamav
    ;;
esac

		
