#!/static/bin/ash

#lesslinux provides preppartitions
#lesslinux patience
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
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
	device=''
	if [ -f /var/run/lesslinux/preppartitions ] ; then
		device=`cat /var/run/lesslinux/preppartitions `
	else
		exit 0
	fi
	mkdir -p /lesslinux/boot
	mount -t vfat -o rw,iocharset=utf8 ${device}1 /lesslinux/boot
	if [ -f /lesslinux/cdrom/boot/kickstart.xd3 ]  ; then
		for f in ` cat /lesslinux/cdrom/lesslinux/boot.sha | awk '{print $2}' `; do
			cat /lesslinux/cdrom/boot/kernel/${f} >> /lesslinux/boot/boot/kickstart.raw
		done
		xdelta3 -d -s /lesslinux/boot/boot/kickstart.raw /lesslinux/cdrom/boot/kickstart.xd3 \
			/lesslinux/boot/boot/kickstart.iso && rm /lesslinux/boot/boot/kickstart.raw
	fi
	sync
	umount /lesslinux/boot || umount /lesslinux/boot 
	# Use mtools to hide some files from Windows
	sed -i "s%/dev/disk/by-label/USBDATA%${device}1%g" /etc/mtools.conf 
	for d in boot EFI loader ; do
		mattrib +r +h / X:/${d}
	done
	# Check if there is enough space behind the partition table for another ISO image
	devsize=`     parted -m -s ${device} unit b print | grep msdos | awk -F ':|B:' '{print $2}' ` 
	partend=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $3}'  `
	isosize=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $2}'  `
	isotwostart=` expr $devsize - $isosize - 8388608 ` 
	# Exit gracefully if size is not sufficient
	[ "$isotwostart" -lt "$partend" ] && exit 0
	# Determine the end of our new loop device by matching an 8M chunk towards the end of the device: 
	loopendblock=` expr '(' $devsize - $isosize ')' / 8388608 - 1 ` 
	# Create a loop device with correct parameters 
	freeloop=` losetup -f ` 
	losetup -o ` expr $partend + 1 ` --sizelimit ` expr $loopendblock '*' 8388608 - $partend - 1 ` $freeloop $device
	dd if=/dev/zero bs=1M count=8 of=${freeloop} 
	# Calculate numbers of blocks needed:
	# BLOB first
	blobblocks=0
	if [ "$blobsize" -gt 63 ] ; then
		blobblocks=` expr $blobsize / 8 ` 
	else
		blobblocks=1
	fi
	# Swap size
	swapblocks=0
	if [ "$swapsize" -gt 63 ] ; then
		swapblocks=` expr $swapsize / 8 ` 
	else
		swapblocks=1
	fi
	# encrypted home
	# Recalculate the possible size of the partition for the encrypted home container
	loopblocks=` expr $loopendblock - '(' $partend / 8388608 ')' ` 
	hcblocks=1
	if [ "$homecontmax" -gt 0 ] ; then
		hcmaxblocks=` expr $homecontmax / 8 ` 
		hcminblocks=` expr $homecontmin / 8 ` 
		hcpossible=` expr $loopblocks - $blobblocks - $swapblocks ` 
		if [ "$hcpossible" -gt $hcmaxblocks ] ; then
			hcblocks=$hcmaxblocks
		else
			hcblocks=$hcpossible
		fi
	fi
	
	# Create partition table: 
	parted -s "$freeloop" mklabel gpt
	
	# First partition - Swap
	swappartlabel="${brandshort}-SWAP"
	[ "$swapblocks" -lt 32 ] && swappartlabel=empty
	parted -s $freeloop unit B mkpart "${swappartlabel}" ext2 1048576 ` expr $swapblocks '*' 8388608 - 1 ` 

	# Second partition - Blob
	blobpartlabel="${brandshort}-BLOB"
	[ "$blobblocks" -lt 32 ] && blobpartlabel=empty
	if [ "$hcblocks" -lt 32 ] ; then
		parted -s $freeloop unit B mkpart "${blobpartlabel}" ext2 ` expr $swapblocks '*' 8388608 ` 100% 
	else
		parted -s $freeloop unit B mkpart "${blobpartlabel}" ext2 ` expr $swapblocks '*' 8388608 `  ` expr '(' $swapblocks + $blobblocks ')' '*' 8388608 - 1 `
		# Third partition - encrypted container
		homepartlabel="${brandshort}-HOME"
		[ "$hcblocks" -lt 32 ] && homepartlabel=empty
		parted -s $freeloop unit B mkpart "${homepartlabel}" ext2 ` expr '(' $swapblocks + $blobblocks ')' '*' 8388608 ` 100% 
	fi
	sync 
	parted -s -m $freeloop unit B print > /var/run/lesslinux/looppart.txt
	losetup -d $freeloop 
	p1start=` grep '^1' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $2}' `
	p1size=`  grep '^1' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $4}' `
	p2start=` grep '^2' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $2}' `
	p2size=`  grep '^2' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $4}' `
	p3start=` grep '^3' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $2}' `
	p3size=`  grep '^3' /var/run/lesslinux/looppart.txt | awk -F ':|B:' '{print $4}' `
	if [ "$swapblocks" -gt 1  ] ; then
		nextloop=` losetup -f ` 
		losetup $nextloop -o $(( $p1start + $partend + 1 )) --sizelimit $p1size $device
		if=/dev/zero bs=1M count=8 of=$nextloop
		mkfs.ext2 -F -L LessLinuxSwap $nextloop
		sync
		losetup -d $nextloop
	fi
	if [ "$blobblocks" -gt 1  ] ; then
		nextloop=` losetup -f ` 
		losetup $nextloop -o $(( $p2start + $partend + 1 )) --sizelimit $p2size $device
		if=/dev/zero bs=1M count=8 of=$nextloop
		mkfs.ext2 -F -L LessLinuxBlob $nextloop
		sync
		losetup -d $nextloop
	fi 
	if [ "$hcblocks" -gt 31  ] ; then
		nextloop=` losetup -f ` 
		losetup $nextloop -o $(( $p3start + $partend + 1 )) --sizelimit $p3size $device
		if=/dev/zero bs=1M count=8 of=$nextloop
		mkfs.ext2 -F -L LessLinuxCrypt $nextloop
		sync 
		losetup -d $nextloop
	fi 
	
	# FIXME: Write UUIDs to bootloader config! 
	exit 0
    ;;
esac
		
# The end	
