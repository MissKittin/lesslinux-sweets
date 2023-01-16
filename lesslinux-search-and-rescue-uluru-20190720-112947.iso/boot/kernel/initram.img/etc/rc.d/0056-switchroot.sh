#!/static/bin/ash

#lesslinux provides switchroot

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if [ -n "$switchuuid" -a -x /static/sbin/blkid.static ] ; then 
		printf "$bold===> Switch RootFS $normal \n" 
		mkdir -p /var/run/lesslinux
		mkdir -p /newroot 
		rootdev=''
		trycount=0
		while [ -z "$rootdev" -a $trycount -lt 15 ] ; do
			rootdev=` /static/sbin/blkid.static -U "$switchuuid" ` 
			[ -z "$rootdev" ] && rootdev=` /static/sbin/blkid.static -L "$switchuuid" ` 
			readorwrite="ro"
			[ -n "$switchread" ] && readorwrite="$switchread" 
			[ -n "$rootdev" ] && mount -o "$readorwrite" "$rootdev" /newroot
			if mountpoint -q /newroot ; then
				firmloop=` cat /proc/mounts | grep ' /lib/firmware ' | awk '{print $1}' `
				umount $firmloop
				losetup -d $firmloop
				moduloop=` cat /proc/mounts | grep ' /lib/modules/' | awk '{print $1}' `
				umount $moduloop
				losetup -d $moduloop
				umount /tmp
				umount /home
				umount /dev/pts
				umount /dev/shm
				mount --move /sys /newroot/sys
				mount --move /proc /newroot/proc
				mount --move /dev /newroot/dev
				# This is needed by ChromiumOS - otherwise it will crash 
				mkdir -p /newroot/dev/.initramfs
				exit 0 
			fi
			trycount=` expr $trycount + 1 `
			sleep 2
		done
		mountpoint -q /newroot || touch /var/run/lesslinux/switchroot_failed 
	fi
    ;;
esac
#		
