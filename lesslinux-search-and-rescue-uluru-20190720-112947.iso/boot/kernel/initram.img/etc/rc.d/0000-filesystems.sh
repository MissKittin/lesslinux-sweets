#!/static/bin/ash

#lesslinux provides systemfs

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Mount some initial filesystems
case $1 in
    start)
    printf "$bold===> Preparing the system$normal\n"
    
    # Try to find out if a squashfs container for the modules exists, mount it!
    kversion=` uname -r ` 
    if [ -f /lesslinux/modules/${kversion}.sqs ] ; then
	mkdir -p /lib/modules/${kversion}
	free_loop=` losetup -f `
	losetup $free_loop /lesslinux/modules/${kversion}.sqs
	mount -t squashfs $free_loop /lib/modules/${kversion}
    fi
    if [ -f /lesslinux/modules/firmware.sqs ] ; then
	mkdir -p /lib/firmware
	free_loop=` losetup -f `
	losetup $free_loop /lesslinux/modules/firmware.sqs
	mount -t squashfs $free_loop /lib/firmware
    fi
    
    # Mount /tmp and /home on separate ramdisks
    if mountpoint -q /tmp ; then
	# printf "$bold---> Skipping /tmp, already mounted $normal\n"
	true
    else
	if [ "$tmpsize" -gt 0 ] ; then
		mount -t tmpfs -o noexec,nosuid,nodev,size=${tmpsize}m tmpfs /tmp
	else
		# calculate the size of /tmp
		# if total memory is 1536MB or larger -> take total memory minus 768MB
		# else -> take half of the total memory
		# FIXME: on systems with swapfiles/ramzswap we have to add an appropriate value!
		memtotal=` cat /proc/meminfo | grep '^MemTotal' | awk '{print $2}' `
		memmeg=` expr $memtotal / 1024 `
		tmpmeg=32
		if [ "$memmeg" -gt 1536 ] ; then 
			tmpmeg=` expr $memmeg - 768 `
		else
			tmpmeg=` expr $memmeg / 2 `
		fi
		mount -t tmpfs -o noexec,nosuid,nodev,size=${tmpmeg}m tmpfs /tmp
	fi
    fi
    mountpoint -q /home || mount -t tmpfs tmpfs -o mode=0755,nosuid,nodev,size=${homesize}m /home
    tar -C /home -xzf /etc/lesslinux/skel/surfer.tgz 
    
    # Change some access modes of devices
    chmod 0666 /dev/tty
    chmod 0666 /dev/pty*
    
    # mdev needs a shell at /bin/sh
    [ '!' -f /bin/sh ] && ln /static/bin/busybox /bin/sh
    echo /static/sbin/mdev > /proc/sys/kernel/hotplug
    mdev -s
    chmod 0666 /dev/null
    chmod 0664 /dev/urandom
    chmod 0664 /dev/random
    chmod 0664 /dev/zero
    
    # And configure the loopback interface
    ifconfig lo 127.0.0.1 
    
    # Write the branding
    cat /etc/lesslinux/branding/filelist.txt | sort | uniq | while read fname ; do
	if [ -f "$fname"."$lang" ] ; then
	    ln -sf "$fname"."$lang" "$fname"
	elif [ -f "$fname".en ] ; then
	    ln -sf "$fname".en "$fname"
	fi
    done
    
    # The earlier the better: Identify bad memory
    if dmesg | grep -q 'bad mem addr' ; then
	dmesg | grep 'bad mem addr' > /var/run/lesslinux/bad_memory
    fi
    if dmesg | grep -q 'early_memtest' ; then
	dmesg | grep 'early_memtest' > /var/run/lesslinux/early_memtest
    fi
    # 
    
  ;;
esac    
#		
