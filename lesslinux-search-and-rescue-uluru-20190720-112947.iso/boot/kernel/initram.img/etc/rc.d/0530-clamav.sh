#!/static/bin/ash
		
#lesslinux provides clamav
#lesslinux parallel
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
        mkdir -p /media
	if mountpoint -q /opt/share/clamav ; then
	    printf "$bold===> Skipping ClamAV, already mounted $normal\n"
	else
	    printf "$bold===> Preparing ClamAV $normal\n"
	    if test -d /lesslinux/blobpart/ClamAV/clamav && touch /lesslinux/blobpart/ClamAV/.touche ; then
		mount --bind /lesslinux/blobpart/ClamAV/clamav /opt/share/clamav 
		chown -R clamav:clamav /opt/share/clamav
	    elif mountpoint -q /lesslinux/blobpart ; then
		mkdir -p /lesslinux/blobpart/ClamAV
		tar -C /opt/share -cf - clamav | tar -C /lesslinux/blobpart/ClamAV -xf - 
		mount --bind /lesslinux/blobpart/ClamAV/clamav /opt/share/clamav 
		chown -R clamav:clamav /opt/share/clamav
	    else
		rand=` dd if=/dev/urandom bs=1024 count=32 2> /dev/null | sha1sum | awk '{print $1}' `
		tar -cf /tmp/clamav_${rand}.tar /opt/share/clamav
		mount -o mode=755 -t tmpfs tmpfs /opt/share/clamav
		tar -C / -xf /tmp/clamav_${rand}.tar
		chown clamav:clamav /opt/share/clamav
		rm /tmp/clamav_${rand}.tar
		chmod 0755 /opt/share/clamav
		chown -R clamav:clamav /opt/share/clamav
	    fi
	    [ -f /etc/freshclam.conf ] || cp -v /etc/freshclam.conf.sample /etc/freshclam.conf
	    sed -i 's/^Example/\#Example/g' /etc/freshclam.conf
	    [ -f /opt/share/clamav/daily.cld -a -f /opt/share/clamav/daily.cvd ] && rm /opt/share/clamav/daily.cld
	    /sbin/ldconfig -f /etc/ld.so.conf > /dev/null 2>&1
	fi
	touch /var/log/lesslinux/bootlog/clamav.done
    ;;
    stop)
	printf "$bold===> Unmounting ClamAV signatures $normal\n"
	if mountpoint -q /opt/share/clamav ; then
	    if mountpoint -q /opt/share/clamav ; then
		umount /opt/share/clamav
	    elif [ -f /lesslinux/cdrom/lesslinux/blob/clamav/main.cvd ] ; then
		mount -o remount,rw /lesslinux/cdrom
		chown -R clamav:clamav /lesslinux/cdrom/lesslinux/blob/clamav
		chmod -R 0755 /lesslinux/cdrom/lesslinux/blob/clamav
		tar -C /opt/share/clamav -cf - . | tar -C /lesslinux/cdrom/lesslinux/blob/clamav -xf - 2>/dev/null
	    fi
	    fuser -km -9 /opt/share/clamav
	fi
	umount /opt/share/clamav
    ;;
esac

		
