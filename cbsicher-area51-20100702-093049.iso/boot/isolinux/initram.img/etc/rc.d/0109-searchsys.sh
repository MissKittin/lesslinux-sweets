#!/static/bin/ash

#lesslinux provides searchsys
#lesslinux license BSD
#lesslinux patience

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
	

mount_and_check() {
	# $1: device
	# $2: filesystem
	# $3: whether to skip isoloop or not 1/0
	device="$1"
	filesystem="$2"
	skiploop="$3"
	[ -f /var/run/lesslinux/cdfound ] && return 0
	[ -b "$device" ] || return 0
	thisversion=` cat /etc/lesslinux/updater/version.txt `
	if [ "$filesystem" = "linux" ] ; then
	    mount -o ro $device /lesslinux/cdrom
	elif [ "$filesystem" = "ntfs" ] ; then
	    mount -t $filesystem -o ro $device /lesslinux/cdrom 2>/dev/null
	else
	    mount -t $filesystem -o ro $device /lesslinux/cdrom 2>/dev/null
	fi
	thatversion=` cat /lesslinux/cdrom/${contdir}/version.txt ` 2>/dev/null
	if [ "$thisversion" = "$thatversion" ] ; then
		touch /var/run/lesslinux/cdfound
		echo -n "$device" > /var/run/lesslinux/install_source
		echo "bootdevice=$device" > /var/run/lesslinux/startup_vars
		echo "bootmode=plain" >> /var/run/lesslinux/startup_vars
		if ( echo "$device" | grep -E  '/dev/sd[a-z]$' > /dev/null 2>&1 ) && \
		   ( cat /proc/mounts | grep "$device" | grep "iso9660" > /dev/null 2>&1 ) ; then
			echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
		else
			echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
		fi
	else
		if [ "$skiploop" -lt "1" ] ; then
			find /lesslinux/cdrom -type f -name '*.iso' -maxdepth 3 | while read isofile ; do
				printf "$bold...> Checking ISOLOOP $isofile $normal\n"
				free_loop=` losetup -f `
				losetup $free_loop $isofile
				mkdir /lesslinux/isoloop
				mount $free_loop /lesslinux/isoloop > /dev/null 2>&1
				thatversion=` cat /lesslinux/isoloop/${contdir}/version.txt ` 2> /dev/null
				if [ "$thisversion" = "$thatversion" ] ; then
					touch /var/run/lesslinux/cdfound
					touch /var/run/lesslinux/isoloop
					echo -n "$free_loop" > /var/run/lesslinux/install_source
					echo "bootdevice=$device" > /var/run/lesslinux/startup_vars
				        echo "bootmode=loop" >> /var/run/lesslinux/startup_vars
				        echo "loopfile=$isofile" >> /var/run/lesslinux/startup_vars
				        echo "loopdev=$free_loop" >> /var/run/lesslinux/startup_vars
					if ( echo "$device" | grep -E  '/dev/sd[a-z]$' > /dev/null 2>&1 ) && \
					   ( cat /proc/mounts | grep "$device" | grep "iso9660" > /dev/null 2>&1 ) ; then
			                    echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
					else
					    echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
			                fi
				else
					umount /lesslinux/isoloop > /dev/null 2>&1
					losetup -d $free_loop > /dev/null 2>&1
				fi
			done
		fi
	fi
	[ -f /var/run/lesslinux/cdfound ] || umount /lesslinux/cdrom 2>/dev/null
}

case $1 in
    start)
        if [ -f /var/run/lesslinux/cdfound ] ; then
	    printf "$bold===> Skip search for LESSLINUX System $normal\n"
	else
	    printf "$bold===> Searching for LESSLINUX System $normal\n"
	    mkdir -p /lesslinux/cdrom
	    [ "$usbsettle" -gt 1 ] && sleep $usbsettle && mdev -s
	    alreadychecked=""
	    skipisos=0
	    if echo "$skipsearch" | grep '|isoloop|' ; then
		skipisos=1
	    fi
	    for i in ` seq $usbwait ` ; do
	    
		if echo "$skipsearch" | grep -v '|linux|' > /dev/null 2>&1 ; then
			# Checking Linux partitions
			linparts=` fdisk -l | grep ' Linux' | awk '{ print $1}' `
			for j in $linparts ; do
				if echo "$alreadychecked" | grep -v "$j " > /dev/null 2>&1 ; then
					alreadychecked="$alreadychecked $j "
					printf "$bold...> Checking Linux partition $j $normal\n"
					mount_and_check $j linux $skipisos
				fi
			done
	        fi
		
		# Checking Superfloppy devices
	        # Checking Isohybrid devices
	        for j in /dev/sd[a-z] ; do
		    if echo "$alreadychecked" | grep -v "$j " > /dev/null 2>&1 ; then
			alreadychecked="$alreadychecked $j "
			if echo "$skipsearch" | grep -v '|superfloppy|' > /dev/null 2>&1 ; then
				[ -b "$j" ] && printf "$bold...> Checking SUPERFLOPPY $j $normal\n"
				mount_and_check $j vfat $skipisos
			fi
			if echo "$skipsearch" | grep -v '|isohybrid|' > /dev/null 2>&1 ; then
				[ -b "$j" ] && printf "$bold...> Checking ISOHYBRID $j $normal\n"
				mount_and_check $j iso9660 $skipisos
			fi
		    fi
		done
	    
		if echo "$skipsearch" | grep -v '|vfat|' > /dev/null 2>&1 ; then
			# Checking FAT partitions
			fatparts=` fdisk -l | grep ' FAT' | awk '{ print $1}' `
			for j in $fatparts ; do
				if echo "$alreadychecked" | grep -v "$j " > /dev/null 2>&1 ; then
					alreadychecked="$alreadychecked $j "
					printf "$bold...> Checking FAT partition $j $normal\n"
					mount_and_check $j vfat $skipisos
				fi
			done
		fi
		
		if echo "$skipsearch" | grep -v '|cddvd|' > /dev/null 2>&1 ; then
			# Checking CD/DVD devices
			for j in /dev/sr[0-9] ; do
				if echo "$alreadychecked" | grep -v "$j " > /dev/null 2>&1 ; then
					printf "$bold...> Checking CD/DVD $j $normal\n"
					mount_and_check $j iso9660 $skipisos
				fi
			done
		fi
		
		if echo "$skipsearch" | grep -v '|ntfs|' > /dev/null 2>&1 ; then
			# Checking NTFS partitions
			ntfsparts=` fdisk -l | grep ' HPFS/NTFS' | awk '{ print $1}' `
			for j in $ntfsparts ; do
				if echo "$alreadychecked" | grep -v "$j " > /dev/null 2>&1 ; then
					alreadychecked="$alreadychecked $j "
					printf "$bold...> Checking NTFS partition $j $normal\n"
					mount_and_check $j ntfs $skipisos
				fi
			done
		fi
		
		[ -f /var/run/lesslinux/cdfound ] || sleep 5
	    done
	fi
    ;;
esac
		
# The end	
