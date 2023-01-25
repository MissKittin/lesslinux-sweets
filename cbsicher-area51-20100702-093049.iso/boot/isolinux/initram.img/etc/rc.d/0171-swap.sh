#!/static/bin/ash
		
#lesslinux provides swap
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Searching swap file $normal\n"
	modprobe dm_mod
	modprobe dm_crypt
        parts=` fdisk -l | grep -E ' FAT| Linux' | awk '{ print $1}' `
	mkdir -m 0700 /lesslinux/cryptswap
	mkdir -m 0700 /lesslinux/cryptkeys
	swapfile=""
	for i in $parts ; do
	    if cat /proc/mounts | awk '{print $1}' | grep "$i" > /dev/null ; then
		mountpoint=` cat /proc/mounts | grep "^$i " | awk '{print $2}' `
		if [ -f "${mountpoint}/swapfile.cry" ] ; then
		    swapfile="${mountpoint}/swapfile.cry"
		fi
	    else
		mountpoint=/lesslinux/cryptswap
		mount $i $mountpoint
		if [ -f "${mountpoint}/swapfile.cry" ] ; then
		    swapfile="${mountpoint}/swapfile.cry"
		else
		    umount $mountpoint
		fi
	    fi
	done
	if [ -n "$swapfile" ] ; then
	    touch /lesslinux/cryptkeys/swap.key
	    chmod 0600 /lesslinux/cryptkeys/swap.key
	    echo "$swapfile" > /var/run/lesslinux/swapfile
	    dd if=/dev/urandom bs=32768 count=32 of=/lesslinux/cryptkeys/swap.key
	    lodev=` losetup -f `
	    echo "$lodev" > /var/run/lesslinux/swapdev
	    losetup $lodev $swapfile
	    dd if=/dev/urandom of=$lodev bs=1M count=8
	    cryptsetup luksFormat -c aes-cbc-essiv:sha256 -s 256 -q $lodev /lesslinux/cryptkeys/swap.key
	    cryptsetup luksOpen $lodev cryptswap --key-file /lesslinux/cryptkeys/swap.key
	    mkswap /dev/mapper/cryptswap
	    swapon /dev/mapper/cryptswap
	    rm /lesslinux/cryptkeys/swap.key
	fi
    ;;
    stop)
	if [ -f /var/run/lesslinux/swapfile ] ; then
	    printf "$bold===> Disabling swap file $normal\n"
	    swapoff /dev/mapper/cryptswap
	    cryptsetup luksClose /dev/mapper/cryptswap
	    losetup -d ` cat /var/run/lesslinux/swapdev `
	    umount /lesslinux/cryptswap
	    rm /var/run/lesslinux/swapfile
	    rm /var/run/lesslinux/swapdev
	fi
    ;;
esac    

		
