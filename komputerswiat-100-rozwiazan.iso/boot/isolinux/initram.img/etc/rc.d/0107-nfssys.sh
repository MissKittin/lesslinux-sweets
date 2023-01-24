#!/static/bin/ash
		
#lesslinux provides nfssys
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
	start)
		isofile=/lesslinux/cdrom/lesslinux.iso
		if [ -f /var/run/lesslinux/cdfound ] || [ -z "$nfs" ]; then
			printf "$bold===> Skip search for LESSLINUX system on NFS$normal\n"
		else
			mkdir /lesslinux/cdrom
			mkdir /lesslinux/isoloop
			thisversion=` cat /etc/lesslinux/updater/version.txt `
			/static/bin/mount -t nfs -o ro,nolock,noatime,proto=tcp "$nfs" /lesslinux/cdrom 
			find /lesslinux/cdrom -type f -name '*.iso' -maxdepth 3 | while read isofile ; do
				printf "$bold...> Checking ISOLOOP $isofile $normal\n"
				free_loop=` losetup -f `
				losetup $free_loop $isofile
				mount $free_loop /lesslinux/isoloop > /dev/null 2>&1
				thatversion=` cat /lesslinux/isoloop/${contdir}/version.txt ` 2> /dev/null
				if [ "$thisversion" = "$thatversion" ] ; then
					touch /var/run/lesslinux/cdfound
					touch /var/run/lesslinux/isoloop
					echo -n "$free_loop" > /var/run/lesslinux/install_source
					echo "bootdevice=nfs" > /var/run/lesslinux/startup_vars
				        echo "bootmode=loop" >> /var/run/lesslinux/startup_vars
				        echo "loopfile=$isofile" >> /var/run/lesslinux/startup_vars
				        echo "loopdev=$free_loop" >> /var/run/lesslinux/startup_vars
					echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
				else
					umount /lesslinux/isoloop > /dev/null 2>&1
					losetup -d $free_loop > /dev/null 2>&1
				fi
			done
			[ -f /var/run/lesslinux/cdfound ] || umount /lesslinux/cdrom 2>/dev/null
		fi
	;;
esac

		
		
