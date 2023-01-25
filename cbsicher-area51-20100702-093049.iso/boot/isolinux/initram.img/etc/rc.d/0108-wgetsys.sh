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
		isofile=/lesslinux/cdrom/lesslinux.iso
		if [ -f /var/run/lesslinux/cdfound ] ; then
			printf "$bold===> Skip search for LESSLINUX System $normal\n"
		elif [ -n "$wgetiso" ] ; then
			thisversion=` cat /etc/lesslinux/updater/version.txt `
			printf "$bold===> Downloading LESSLINUX System $normal\n"
			mkdir -p /lesslinux/cdrom
			mkdir -p /lesslinux/isoloop
			wget -O "$isofile" "$wgetiso"
			free_loop=` losetup -f `
			losetup $free_loop $isofile
			mount $free_loop /lesslinux/isoloop > /dev/null 2>&1
			thatversion=` cat /lesslinux/isoloop/${contdir}/version.txt ` 2> /dev/null
			if [ "$thisversion" = "$thatversion" ] ; then
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
				losetup -d $free_loop > /dev/null 2>&1
				rm "$isofile"
			fi
		fi
	;;
esac

		
		
