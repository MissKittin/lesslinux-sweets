#!/static/bin/ash
		
#lesslinux provides toram
#lesslinux license BSD
#lesslinux description
# Copy ISO image to memory

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/rc.subr/progressbar

case $1 in
    start)
	mem_avail=` cat /proc/meminfo | grep MemTotal | awk '{print $2}' `
	copydevice=''
	contdevice=''
	isoblocks=0
	filesys=''
	sysdevice=''
	outerfs=''
	if mountpoint -q /lesslinux/isoloop ; then
		copydevice=` cat /proc/mounts | grep /lesslinux/isoloop | awk '{print $1}' `
		contdevice=` cat /proc/mounts | grep /lesslinux/cdrom | awk '{print $1}' ` 
		sysdevice=$contdevice
		isoblocks=` df -k /lesslinux/isoloop | tail -n 1 | awk '{print $2}' `
		filesys=` cat /proc/mounts | grep /lesslinux/isoloop | awk '{print $3}' `
		outerfs=` cat /proc/mounts | grep /lesslinux/cdrom   | awk '{print $3}' `
	else
		copydevice=` cat /proc/mounts | grep /lesslinux/cdrom | awk '{print $1}' `
		sysdevice=$copydevice
		isoblocks=` df -k /lesslinux/cdrom | tail -n 1 | awk '{print $2}' `
		filesys=` cat /proc/mounts | grep /lesslinux/cdrom | awk '{print $3}' `
		outerfs=` cat /proc/mounts | grep /lesslinux/cdrom | awk '{print $3}' `
	fi
	if [ "$optram" -gt 0 ] ; then
		if echo $sysdevice | grep '^/dev/sr' ; then
			echo '---> System device is on optical media, start copying to RAM'
		elif [ "$outerfs" = "ntfs" -o "$outerfs" = "fuseblk" ] ; then
			echo '---> System device is on NTFS, start copying to RAM'
		else
			echo '---> System device is not on optical media, skip copying to RAM'
			exit 1
		fi
	fi
	allowedfs=''
	for fs in udf iso9660 squashfs ; do
		[ "$fs" = "$filesys" ] && allowedfs=$filesys
	done
	[ -z "$allowedfs" ] && exit 1
	# toram=0 : never copy to RAM
	# toram=1 : always copy to RAM
	# toram=n : copy to RAM if available memory is n kilobytes larger than larger than the media
	copy_toram="false"
	if [ "$toram" -eq 1 ] && [ -z "$wgetiso" ] ; then
		copy_toram="true"
	elif [ "$toram" -gt 1 ] ; then
		ramneed=` expr $isoblocks + $toram ` 
		[ "$mem_avail" -gt "$ramneed" ] && copy_toram="true"
	fi
	if [ "$copy_toram" = "true" ] ; then
		printf "$bold===> Copying LESSLINUX ISO image to RAM $normal\n"
		echo -e '\033[9;0]\033[14;0]' > /dev/console
		copyblocks=` expr $isoblocks / 2 ` 
		mkdir -p /lesslinux/ramiso
		kblocks=`expr $isoblocks + 8192 ` 
		mount -t tmpfs -o mode=0755,size=${kblocks}k tmpfs /lesslinux/ramiso 
		if [ "$ultraquiet" -gt 1 ] ; then
			if [ "$ultraquiet" -eq 3 -a -p /splash.fifo ] ; then
				echo 0 > /splash.fifo
				fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/toram.ppm 
			fi
			genericpgbar 0 32 "$copying_toram" "0%" "" tty1
			largeblocks=` expr $copyblocks / 2048 ` 
			for n in ` seq 0 $largeblocks `; do
				percentage=` expr ${n}00 / $largeblocks ` 
				dd if=$copydevice of=/lesslinux/ramiso/lesslinux.iso bs=4194304 count=1 seek=$n skip=$n
				genericpgbar $percentage 32 "$copying_toram" "${percentage}%" "" tty1
				[ -p /splash.fifo ] && echo $percentage > /splash.fifo
			done
			genericpgbar 100 32 "$copying_toram" "100%" "" tty1
			[ -p /splash.fifo ] && echo 100 > /splash.fifo
		else
			dd if=$copydevice of=/lesslinux/ramiso/lesslinux.iso bs=2048 count=$copyblocks
		fi
		umount /lesslinux/isoloop || umount /lesslinux/isoloop
		umount /lesslinux/cdrom || umount /lesslinux/cdrom
		losetup -d $copydevice
		umount /lesslinux/cdrom || umount /lesslinux/cdrom
		freeloop=` losetup -f ` 
		losetup $freeloop /lesslinux/ramiso/lesslinux.iso
		mkdir -p /lesslinux/isoloop
		mount $freeloop /lesslinux/isoloop
		if [ "$ejectcd" -gt 0 ] ; then
			echo $sysdevice | grep '^/dev/sr' && eject $sysdevice 
		fi
		touch /var/run/lesslinux/cdfound
		touch /var/run/lesslinux/isoloop
		echo -n "$freeloop" > /var/run/lesslinux/install_source
		echo "bootdevice=wget" > /var/run/lesslinux/startup_vars
		echo "bootmode=loop" >> /var/run/lesslinux/startup_vars
		echo "loopfile=/lesslinux/ramiso/lesslinux.iso" >> /var/run/lesslinux/startup_vars
		echo "loopdev=$freeloop" >> /var/run/lesslinux/startup_vars
		echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
	fi
    ;;
esac
	
		
