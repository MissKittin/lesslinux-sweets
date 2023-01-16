#!/static/bin/ash
		
#lesslinux provides wgetsys
#lesslinux license BSD
#lesslinux verbose

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors


case $1 in 
	start)
		isofile=/lesslinux/ramiso/lesslinux.iso
		if [ -f /var/run/lesslinux/cdfound ] ; then
			printf "$bold===> Skip search for LESSLINUX System $normal\n"
		elif [ -n "$wgetiso" ] ; then
			if [ -x /static/bin/curl ] && echo "$wgetiso" | grep -q '^http://' ; then
				tmpsize=` curl -I "$wgetiso" | grep Content-Length | awk '{print $2}' `
				overlay=` echo -n "$wgetiso" | sed 's/iso$/tgz/g' ` 
				ovrsize=` curl -I "$overlay" | grep '^Content-Length' | awk '{print $2}' `
				if [ "$tmpsize" -gt 0 ] ; then
					if [ "$ovrsize" -gt 0 ] ; then
						mkdir -p /etc/lesslinux/branding/overlays
						curl -o /etc/lesslinux/branding/overlays/overlay7.tgz "$overlay"
					fi
					wgetsize=` expr "$tmpsize" / 1024 + 16384 ` 
				fi
			fi
			[ "$wgetsize" -lt 1 ] && wgetsize=1048576
			mkdir -p /lesslinux/ramiso
			mount -t tmpfs -o mode=0755,size=${wgetsize}k  tmpfs  /lesslinux/ramiso 
			thisversion=` cat /etc/lesslinux/updater/version.txt `
			printf "$bold===> Downloading LESSLINUX System $normal\n"
			mkdir -p /lesslinux/cdrom
			mkdir -p /lesslinux/isoloop
			if echo "$wgetiso" | grep -q '^tftp://' ; then
				hostpath=` echo "$wgetiso" | sed 's%^tftp://%%g' | sed 's%/% %' `
				tftphost=` echo $hostpath | awk '{print $1}' `
				tftppath=` echo $hostpath | awk '{print $2}' `
				tftp -g -b 32768 -l "$isofile" -r "$tftppath" "$tftphost"
			else
				if [ -x /static/bin/curl ] ; then
					if [ "$console" = tty2 ] ; then
						chvt 8
						curl -o "$isofile" "$wgetiso" 2> /dev/tty8 
						chvt 2
					else
						curl -o "$isofile" "$wgetiso"
					fi
				else
					wget -O "$isofile" "$wgetiso"
				fi
			fi
			free_loop=` losetup -f `
			losetup $free_loop $isofile
			mount $free_loop /lesslinux/isoloop > /dev/null 2>&1
			thatversion=` cat /lesslinux/isoloop/${contdir}/version.txt ` 2> /dev/null
			if [ "$thisversion" = "$thatversion" ] ; then
				# FIXME! Move blobsearch to a separate function
				# FIXME! Newer files should win!
				if [ -d "/lesslinux/isoloop/${contdir}/blob" ] ; then
					mkdir -p /lesslinux/blob
					find "/lesslinux/isoloop/${contdir}/blob" -maxdepth 1 | while read fname ; do
						[ -f "$fname" -o -d "$fname" ] && \
							ln -sf "$fname" /lesslinux/blob/` basename "$fname" ` 
					done
				fi
				touch /var/run/lesslinux/cdfound
				touch /var/run/lesslinux/isoloop
				echo -n "$free_loop" > /var/run/lesslinux/install_source
				echo "bootdevice=wget" > /var/run/lesslinux/startup_vars
				echo "bootmode=loop" >> /var/run/lesslinux/startup_vars
				echo "loopfile=$isofile" >> /var/run/lesslinux/startup_vars
				echo "loopdev=$free_loop" >> /var/run/lesslinux/startup_vars
				echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
			else
				umount /lesslinux/isoloop > /dev/null 2>&1
				losetup -d $free_loop     > /dev/null 2>&1
				umount /lesslinux/cdrom   > /dev/null 2>&1
				# rm "$isofile"
			fi
		fi
	;;
esac

		
		
