#!/static/bin/ash
		
#lesslinux provides blob
#lesslinux license BSD
#lesslinux description
# Prepare development and build environment of LessLinux

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	printf "$bold===> Preparing some filesystems... $normal\n"
	bootdev=` blkid -L LessLinuxBoot ` 
	if [ -n "$bootdev" ] ; then
		mkdir -p /lesslinux/boot
		mountpoint -q /lesslinux/boot || mount -t ext4 -o ro $bootdev /lesslinux/boot
	fi
	efidev=` blkid -L LessEfiBoot `
	if [ -n "$efidev" ] ; then
		mkdir -p /lesslinux/efiboot
		mountpoint -q /lesslinux/efiboot || mount -o ro $efidev /lesslinux/efiboot
	fi
	blobdev=` blkid -L LessLinuxBlob `
	if [ -n "$blobdev" ] ; then
		mountpoint -q /lesslinux/blobpart && exit 0
		mkdir -p /lesslinux/blobpart
		fstype=` blkid -o udev "$blobdev" | grep 'FS_TYPE=ext' | awk -F '=' '{print $2}' `
		if [ "$fstype" = ext2 ] ; then
			# tune2fs -O extents,uninit_bg,dir_index ${blobdev}
			# fsck -fCVD ${blobdev}
			# fsck -fCV ${blobdev}
			# btrfs-convert ${blobdev}
			dd if=/dev/zero bs=1M count=8 of=${blobdev}
			mkfs.btrfs -f -L LessLinuxBlob ${blobdev}
			mount -t btrfs -o relatime,compress $blobdev /lesslinux/blobpart
		elif [ "$fstype" = ext4 ] ; then
			mount -t ext4 -o relatime $blobdev /lesslinux/blobpart
		else
			mount -t btrfs -o relatime,compress $blobdev /lesslinux/blobpart
		fi
		thisversion=` cat /etc/lesslinux/updater/version.txt `
		if [ -f /lesslinux/blobpart/updates/update-${thisversion}.txz ] ; then
			# Check signature first!
			# Import the key
			/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc
			if /usr/bin/gpg --verify /lesslinux/blobpart/updates/update-${thisversion}.txz.asc ; then
				tar -C / -xf /lesslinux/blobpart/updates/update-${thisversion}.txz
			fi
		fi
	fi
    ;;
    stop)
	umount /lesslinux/boot
	umount /lesslinux/efiboot
	umount /lesslinux/blob
	umount /lesslinux/blobpart
    ;;
esac
	
		
