#!/static/bin/ash

#lesslinux provides searchsys
#lesslinux license BSD
#lesslinux patience

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

iso_gpt_convert() {
	echo -e '\033[9;0]\033[14;0]' > /dev/console
	device="$1"
	# Text mode conversion on TTY8 when ultraquiet is not set:
	if [ "$ultraquiet" -lt 2 ] ; then
		chvt 8
		echo "===> Converting ISOhybrid to GPT drive with proper FS, this may take some time" > /dev/tty8
		echo "     but it is done only once..." > /dev/tty8
	fi
	# GUI conversion on TTY8 when fbsplash is running
	if [ "$ultraquiet" -eq 3 -a -p /splash.fifo ] ; then
		echo 0 > /splash.fifo
		fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/01driveconf.ppm 
	fi
	[ "$skipcheck" -lt 2 ] && run_self_test cdrom
	[ "$ultraquiet" -gt 1 ] && genericpgbar 0 32 "$convert_head" "$convert_prepare" "" tty1
	[ "$ultraquiet" -eq 3 -a -p /splash.fifo ] && echo 90 > /splash.fifo
	
	# When installed from batchinstall or USB install the ISOhybrid MBR gets nuked,
	# it should be saved to a file than. Try to find it! On a direct install
	# from Win32DiskImager or dd we should not need it.
	
	# Copy the saved MBR first
	mkdir -p /lesslinux/boot
	mount -t ext4 -o ro ${device}2 /lesslinux/boot
	[ -f /lesslinux/boot/isohybridmbr.bin ] && cp -v /lesslinux/boot/isohybridmbr.bin /tmp
	umount /lesslinux/boot
	
	# Size of boot/isolinux directory in kilobytes
	bootsize=` du -sk /lesslinux/cdrom/boot | awk '{print $1}' `
	efidirsize=` du -sk /lesslinux/cdrom/boot/efi | awk '{print $1}' `
	[ -z "$efidirsize" ] && efidirsize=0
	bootsize=` expr $bootsize - $efidirsize ` 
	# Size of boot partition in count of 8MB blocks - roughly add 50% for updates
	bootblocks=` expr $bootsize / 5461 + 1 ` 
	
	# Size of boot/efi.img in bytes
	efisize=` ls -la /lesslinux/cdrom/boot/efi/efi.img | awk '{print $5}' ` 
	[ -z "$efisize" ] && efisize=0 
	# Size of EFI boot partition in count of 8MB blocks - roughly add 50% for updates
	efiblocks=` expr $efisize / 5592404 ` 
	[ "$efiblocks" -lt 1 ] && efiblocks=1
	# Size of ISO image in kilobytes
	isosize=` df -k | grep '/lesslinux/cdrom' | awk '{print $3}' `
	# Size of ISO partition in count of 8MB blocks - roughly add 25% for updates
	isoblocks=` expr $isosize / 6553 + 1 ` 
	# echo "Isoblocks: $isoblocks"
	# Size of device in kilobyte blocks
	shortdev=` echo -n $device | sed 's%/dev/%%g' ` 
	devicesize=` cat /proc/partitions | grep "$shortdev"'$' | awk '{print $3}' ` 
	# Size of device in 8MB blocks - there might be little bit less than 8MB left out
	deviceblocks=` expr $devicesize / 8192 ` 
	# echo "Deviceblocks: $deviceblocks"
	hcminblocks=0
	hcmaxblocks=0 
	if [ "$homecontmax" -gt 0 ] ; then
		hcmaxblocks=` expr $homecontmax / 8 ` 
		hcminblocks=` expr $homecontmin / 8 ` 
	fi
	# blobblocks 
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
	# Now check for minimum free space - FIXME: 128MB are not good to be hard coded
	neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
	# echo "Neededblocks: $neededblocks"
	if [ "$deviceblocks" -lt "$neededblocks" ] ; then
		# Try without swap:
		swapblocks=1
		neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
		if [ "$deviceblocks" -lt "$neededblocks" ] ; then
			hcminblocks=0
			hcmaxblocks=0 
			neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $efiblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
			if [ "$deviceblocks" -lt "$neededblocks" ] ; then
				[ "$ultraquiet" -lt 3 ] && echo "===> FAILED. Device too small." > /dev/tty8
				echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
				[ "$ultraquiet" -lt 3 ] && chvt 1
				return 1
			fi
		fi
	fi
	
	# Delete some MB at the end of the disk to remove remaining GUID backup table
	dd if=/dev/zero of=$device bs=8388608 seek=` expr $deviceblocks - 4 ` 2>/dev/null
	
	# Copy license information that might be hidden
	dd if=$device of=/tmp/license.bin bs=1024 skip=2 count=1 
	
	# Let the games begin...
	umount /lesslinux/cdrom
	lastct=` expr $isoblocks - 1 ` 
	[ "$ultraquiet" -lt 3 ] && echo '---> Moving filesystem' > /dev/tty8
	[ "$ultraquiet" -lt 3 ] && echo -n '0%' > /dev/tty8
	[ "$ultraquiet" -gt 1 ] && genericpgbar 0 32 "$convert_head" "$convert_move" "" tty1
	
	if [ "$ultraquiet" -eq 3 -a -p /splash.fifo ] ; then
		echo 0 > /splash.fifo
		fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/02driveconf.ppm 
	fi
	
	for i in ` seq 0 $lastct ` ; do
		percentage=` expr ${i}00 / ${isoblocks} `
		[ "$ultraquiet" -lt 3 ] && printf '\033[10D' > /dev/tty8 
		[ "$ultraquiet" -lt 3 ] && printf "${percentage}" > /dev/tty8
		[ "$ultraquiet" -lt 3 ] && echo -n '%' > /dev/tty8
		[ -p /splash.fifo ] && echo "${percentage}" > /splash.fifo
		# go backwards
		copyblock=` expr $lastct - $i ` 
		tries=0
		copyok=0
		while [ $tries -lt 9 -a $copyok -lt 1 ] ; do
			dd if=$device of=/lesslinux/copyblock.bin bs=8388608 count=1 skip=$copyblock 2>/dev/null
			dd if=/lesslinux/copyblock.bin of=$device bs=8388608 count=1 seek=` expr $deviceblocks - $i - 2 ` 2>/dev/null
			sync
			dd if=$device of=/lesslinux/checkblock.bin bs=8388608 count=1 skip=` expr $deviceblocks - $i - 2 ` 2>/dev/null
			md5in=` sha1sum /lesslinux/copyblock.bin | awk '{print $1}' ` 
			md5out=` sha1sum /lesslinux/checkblock.bin | awk '{print $1}' ` 
			tries=` expr $tries + 1 ` 
			if [ $md5in = $md5out ] ; then
				copyok=1
				[ "$ultraquiet" -gt 1 ] && genericpgbar ${percentage} 32 "$convert_head" "${convert_move} - ${percentage}%" "" tty1
			else
				echo "COPY FAILED on $i - trying again. Please consider replacing the target drive!" > /dev/tty8
				[ "$ultraquiet" -gt 1 ] && genericpgbar ${percentage} 32 "$convert_head" "${convert_move} - ${percentage}%" "${convert_error} ${i}" tty1
				[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/07driveconf.ppm 
			fi
		done
	done
	[ "$ultraquiet" -lt 3 ] && printf '\033[10D' > /dev/tty8 
	[ "$ultraquiet" -lt 3 ] && echo '100%' > /dev/tty8
	[ "$ultraquiet" -gt 1 ] && genericpgbar 100 32 "$convert_head" "${convert_move} - 100%" "" tty1
	[ -p /splash.fifo ] && echo 100 > /splash.fifo
	rm /lesslinux/copyblock.bin /lesslinux/checkblock.bin 
	
	[ "$ultraquiet" -lt 3 ] && echo '---> Creating partition table and bootloader' > /dev/tty8
	[ "$ultraquiet" -gt 1 ] && genericpgbar 0 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/05driveconf.ppm
	
	# Recalculate the possible size of the partition for the encrypted home container
	hcblocks=1
	if [ "$homecontmax" -gt 0 ] ; then
		hcmaxblocks=` expr $homecontmax / 8 ` 
		hcminblocks=` expr $homecontmin / 8 ` 
		hcpossible=` expr $deviceblocks - $isoblocks - $isoblocks - $bootblocks - $efiblocks - $blobblocks - $swapblocks - 40 ` 
		if [ "$hcpossible" -gt $hcmaxblocks ] ; then
			hcblocks=$hcmaxblocks
		else
			hcblocks=$hcpossible
		fi
	fi
	
	# Create eight partitions: userdata (1), legacy boot (2), EFI boot (3), blob (4), encrypted home (5), encrypted swap (6), system reserved (for updates, 7), system ISO (8)
	eighthpartstart=`   expr '(' $deviceblocks - $isoblocks - 1 ')' '*' 8388608 `
	seventhpartstart=`  expr '(' $deviceblocks - $isoblocks - $isoblocks - 1 ')' '*' 8388608 `
	sixthpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - 1 ')' '*' 8388608 `
	fifthpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - 1 ')' '*' 8388608 `
	fourthpartstart=`   expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - 1 ')' '*' 8388608 `
	thirdpartstart=`    expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - $efiblocks - 1 ')' '*' 8388608 `
 	secpartstart=`      expr '(' $deviceblocks - $isoblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - $efiblocks - $bootblocks - 1 ')' '*' 8388608 `
	
	# Now overwrite the start of the device
	dd if=/dev/zero bs=1024 count=1024 of="$device"
	# First create an DOS MBR with an active partition 
	##parted -s $device unit B mklabel msdos
	##parted -s $device unit B mkpart primary fat32 512 ` expr $thirdpartstart - 1 `
	##parted -s $device unit B mkpart primary fat32 $thirdpartstart ` expr $fourthpartstart - 1 `
	##parted -s $device unit B mkpart primary fat32 $fourthpartstart '100%'
	##parted -s $device unit B set 2 boot on
	##parted -s $device unit B set 2 esp on
	##printf "print\nt\n3\n17\nwrite\nquit\n" | /static/sbin/fdisk $device
	##printf "print\nt\n1\nee\nwrite\nquit\n" | /static/sbin/fdisk $device
	sync
	# Now backup this partition table
	##dd if="$device" of=/tmp/legacy.mbr bs=512 count=1
	##dd if=/dev/zero bs=1024 count=1 of="$device"
	# Create the GPT partition table
	parted -s $device unit B mklabel gpt
	sync
	mdev -s
	
	[ "$ultraquiet" -gt 1 ] && genericpgbar 5 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 5 > /splash.fifo
	
	# First partition - data
	parted -s $device unit B mkpart "${brandshort}-DATA" fat32 8388608 ` expr $secpartstart - 1 `  
	[ "$ultraquiet" -gt 1 ] && genericpgbar 10 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 10 > /splash.fifo
	
	# Second partition - legacy boot
	parted -s $device unit B mkpart "${brandshort}-BIOS" ext2 $secpartstart ` expr $thirdpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 15 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 15 > /splash.fifo
	parted -s $device unit B set 2 legacy_boot on
	[ "$ultraquiet" -gt 1 ] && genericpgbar 20 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 20 > /splash.fifo
	
	# Third partition - EFI Boot
	parted -s $device unit B mkpart "${brandshort}-UEFI" fat32 $thirdpartstart ` expr $fourthpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 25 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ "$efisize" -gt 0 ] && parted -s $device unit B set 3 boot on
	[ "$ultraquiet" -gt 1 ] && genericpgbar 30 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 30 > /splash.fifo
	
	# Fourth partition - Blob
	blobpartlabel="${brandshort}-BLOB"
	[ "$blobblocks" -lt 32 ] && blobpartlabel=empty
	parted -s $device unit B mkpart "${blobpartlabel}" ext2 $fourthpartstart ` expr $fifthpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 35 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 35 > /splash.fifo
	
	# Fifth partition - encrypted container
	homepartlabel="${brandshort}-HOME"
	[ "$hcblocks" -lt 32 ] && homepartlabel=empty
	parted -s $device unit B mkpart "${homepartlabel}" ext2 $fifthpartstart ` expr $sixthpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 40 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 40 > /splash.fifo
	
	# Sixth partition - Swap
	swappartlabel="${brandshort}-SWAP"
	[ "$swapblocks" -lt 32 ] && swappartlabel=empty
	parted -s $device unit B mkpart "${swappartlabel}" ext2 $sixthpartstart ` expr $seventhpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 45 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 45 > /splash.fifo
	
	# Seventh partition - ISO image reserved
	parted -s $device unit B mkpart "${brandshort}-SYS2" ext2 $seventhpartstart ` expr $eighthpartstart - 1 ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 50 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 50 > /splash.fifo
	
	# Eight partition - ISO image
	parted -s $device unit B mkpart "${brandshort}-SYS1" ext2 $eighthpartstart ` expr '(' $deviceblocks - 1 ')' '*' 8388608 - 1 `
	[ "$ultraquiet" -gt 1 ] && genericpgbar 55 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 55 > /splash.fifo
	
	# Write the MSDOS MBR and the GPT boot legacy block
	# dd of="$device" if=/tmp/legacy.mbr bs=512 count=1
	cat /etc/syslinux/gptmbr.bin > "$device"
	# rm /tmp/legacy.mbr
	
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/06driveconf.ppm
	[ "$ultraquiet" -lt 3 ] && echo '---> Creating file systems' > /dev/tty8
	sync 
	sleep 2
	mdev -s
	sleep 2 
	pgfrac=55
	for part in ` seq 1 7 ` ; do
		dd if=/dev/zero bs=1M count=8 of=${device}${part} 
		pgfrac=` expr $pgfrac + 2 `
		[ "$ultraquiet" -gt 1 ] && genericpgbar $pgfrac 32 "$convert_head" "${convert_mkfs}" "" tty1
		[ -p /splash.fifo ] && echo $pgfrac > /splash.fifo
		sync
	done
	if [ -x /static/sbin/mkntfs.static ] && [ "$secpartstart" -gt 4294967295 ] ; then
		mkntfs.static -F -Q -L USBDATA "${device}1"
	else
		mkfs.vfat -n USBDATA "${device}1"
	fi
	[ "$ultraquiet" -gt 1 ] && genericpgbar 75 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 75 > /splash.fifo
	sleep 2
	sync
	mdev -s
	sleep 2
	
	# Copy the saved ISOhybrid MBR: 
	if [ -f /tmp/isohybridmbr.bin ] ; then
		dd if=/tmp/isohybridmbr.bin of=${device}8 conv=notrunc
		sync
		rm /tmp/isohybridmbr.bin
	fi
	
	mkfs.ext2 -L LessLinuxBoot "${device}2"
	[ "$ultraquiet" -gt 1 ] && genericpgbar 85 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 85 > /splash.fifo
	[ "$blobblocks" -gt 1 ] && mkfs.ext2 -L LessLinuxBlob "${device}4"
	[ "$hcblocks" -gt 1 ]   && mkfs.ext2 -L LessLinuxCrypt "${device}5"
	[ "$swapblocks" -gt 1 ] && mkfs.ext2 -L LessLinuxSwap  "${device}6"
	[ "$ultraquiet" -gt 1 ] && genericpgbar 95 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 95 > /splash.fifo
	mkdir -p /lesslinux/boot
	mkdir -p /lesslinux/data
	mkdir -p /lesslinux/efiboot
	mkdir -p /lesslinux/blobpart
	if [ -x /static/sbin/mkntfs.static ] && [ "$secpartstart" -gt 4294967295 ] ; then
		ntfs-3g.static -o rw "${device}1" /lesslinux/data
	else
		mount -t vfat -o rw "${device}1" /lesslinux/data
	fi
	mount -t ext4 -o rw "${device}2" /lesslinux/boot
	[ "$blobblocks" -gt 1 ] && mount -t ext4 -o relatime "${device}4" /lesslinux/blobpart
	mount -t iso9660 -o ro "${device}8" /lesslinux/cdrom
	newuuid=` blkid.static -o udev "${device}2" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
	cryptuuid=''
	swapuuid=''
	[ "$hcblocks" -gt 1 ]   && cryptuuid=` blkid.static -o udev "${device}5" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
	[ "$swapblocks" -gt 1 ] && swapuuid=`  blkid.static -o udev "${device}6" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
	[ "$ultraquiet" -gt 1 ] && genericpgbar 33 32 "$convert_head" "${convert_bios}" "" tty1
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/03driveconf.ppm
	[ -p /splash.fifo ] && echo 33 > /splash.fifo
	# Copy legacy boot files
	tar -C /lesslinux/cdrom -cf - boot/isolinux boot/grub boot/kernel | tar -C /lesslinux/boot -xf -
	touch /lesslinux/boot/cmdline
	cp -v /tmp/legacy.mbr /lesslinux/boot
	# Copy GRUBs file to properly detect the boot partition
	idfile=` ls /lesslinux/boot/boot/grub/????????.cd `
	idtarg=` echo $idfile | sed 's/\.cd/.pt/g' ` 
	mv $idfile $idtarg
	[ -f /etc/lesslinux/branding/postisoconvert.sh ] && /etc/lesslinux/branding/postisoconvert.sh
	if [ -d /etc/lesslinux/branding/postisoconvert.d ] ; then
		find /etc/lesslinux/branding/postisoconvert.d -type f | sort | while read scrp ; do
			/static/bin/ash $scrp
		done
	fi
	
	[ "$ultraquiet" -gt 1 ] && genericpgbar 66 32 "$convert_head" "${convert_efi}" "" tty1
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/04driveconf.ppm
	[ -p /splash.fifo ] && echo 66 > /splash.fifo
	# Copy EFI boot image
	if [ -f /lesslinux/cdrom/boot/efi/efi.img ] ; then
		dd if=/lesslinux/cdrom/boot/efi/efi.img of="${device}3"
		mount -t vfat -o rw "${device}3" /lesslinux/efiboot
		# Modify EFI boot files
		find /lesslinux/efiboot/loader -type f -name '*.usb' | while read cfgfile ; do 
			outfile=` echo ${cfgfile} | sed 's/\.usb$/.conf/g' `
			cp -v ${cfgfile} ${outfile} 
		done
		find /lesslinux/efiboot/loader -type f -name '*.conf' | while read cfgfile ; do 
			[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
			sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
			[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
			[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
			[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
		done
		mkdir -p /lesslinux/efiboot/boot/isolinux
		extlinux --install /lesslinux/efiboot/boot/isolinux
		sync
		umount /lesslinux/efiboot
	fi
	sync
	umount /lesslinux/blobpart
	
	# Modify legacy boot files
	find /lesslinux/boot/boot/isolinux -type f -name '*.cfg' | while read cfgfile ; do 
		[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
		sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
		[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
		sed -i 's%^INCLUDE /boot/isolinux/boot0x80.cfg%# INCLUDE /boot/isolinux/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^MENU INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# MENU INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^# INCLUDE /boot/isolinux/usbonly%INCLUDE /boot/isolinux/usbonly%g' "${cfgfile}" 
		sed -i 's%^# INCLUDE /boot/isolinux/\([a-z]*\)/usbonly%INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
		sed -i 's%^# MENU INCLUDE /boot/isolinux/\([a-z]*\)/usbonly% MENU INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
	done
	cfg=/lesslinux/boot/boot/isolinux/isolinux.cfg
	[ -f /lesslinux/boot/boot/isolinux/extlinux.conf ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.conf
	[ -f /lesslinux/boot/boot/isolinux/extlinux.conf.${lang} ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.conf.${lang}
	[ -f /lesslinux/boot/boot/isolinux/extlinux.cfg ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.cfg
	[ "$cfg" '!=' /lesslinux/boot/boot/isolinux/extlinux.conf ] && cp "$cfg" /lesslinux/boot/boot/isolinux/extlinux.conf
	sed -i 's/uuid=all/uuid='"${newuuid}"'/g' /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    /lesslinux/boot/boot/isolinux/extlinux.conf

	echo -n "${newuuid}" > /lesslinux/boot/boot.uuid
	echo -n "${cryptuuid}" > /lesslinux/boot/crypt.uuid
	echo -n "${swapuuid}" > /lesslinux/boot/swap.uuid
	extlinux --install /lesslinux/boot/boot/isolinux
	umount /lesslinux/boot
	mount -t ext4 -o ro "${device}2" /lesslinux/boot
	umount /lesslinux/efiboot
	mount -t vfat -o ro "${device}3" /lesslinux/efiboot
	umount /lesslinux/data
	echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
	echo -n "${device}8" > /var/run/lesslinux/install_source
	echo "bootdevice=${device}8" >> /var/run/lesslinux/startup_vars
	[ "$ultraquiet" -lt 3 ] && echo "===> Done." > /dev/tty8
	[ "$ultraquiet" -lt 3 ] && chvt 1
	[ -p /splash.fifo ] && echo 100 > /splash.fifo
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/textblank.ppm	
}

iso_hack_convert() {
	echo -e '\033[9;0]\033[14;0]' > /dev/console
	device="$1"
	# Text mode conversion on TTY8 when ultraquiet is not set:
	if [ "$ultraquiet" -lt 2 ] ; then
		chvt 8
		echo "===> Converting ISOhybrid to GPT drive with proper FS, this may take some time" > /dev/tty8
		echo "     but it is done only once..." > /dev/tty8
	fi
	# GUI conversion on TTY8 when fbsplash is running
	if [ "$ultraquiet" -eq 3 -a -p /splash.fifo ] ; then
		echo 0 > /splash.fifo
		fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/01driveconf.ppm 
	fi
	[ "$skipcheck" -lt 2 ] && run_self_test cdrom
	[ "$ultraquiet" -gt 1 ] && genericpgbar 0 32 "$convert_head" "$convert_prepare" "" tty1
	[ "$ultraquiet" -eq 3 -a -p /splash.fifo ] && echo 90 > /splash.fifo
	
	# FIXME! FIXME!
	# When installed from batchinstall or USB install the ISOhybrid MBR gets nuked,
	# it should be saved to a file than. Try to find it! 
	
	# Size of boot directory in kilobytes, including the EFI boot directory and image
	bootsize=` du -sk /lesslinux/cdrom/boot | awk '{print $1}'  ` 
	# Size of boot partition in count of 8MB blocks - roughly add 50% for updates
	bootblocks=` expr $bootsize / 5461 + 1 ` 
	
	# Size of ISO image in kilobytes
	isosize=` df -k | grep '/lesslinux/cdrom' | awk '{print $3}' `
	# Size of ISO partition in count of 8MB blocks - roughly add 25% for updates
	isoblocks=` expr $isosize / 6553 + 1 `
	
	# Size of device in kilobyte blocks
	shortdev=` echo -n $device | sed 's%/dev/%%g' ` 
	devicesize=` cat /proc/partitions | grep "$shortdev"'$' | awk '{print $3}' ` 
	# Size of device in 8MB blocks - there might be little bit less than 8MB left out
	deviceblocks=` expr $devicesize / 8192 ` 
	
	hcminblocks=0
	hcmaxblocks=0 
	if [ "$homecontmax" -gt 0 ] ; then
		hcmaxblocks=` expr $homecontmax / 8 ` 
		hcminblocks=` expr $homecontmin / 8 ` 
	fi
	# blobblocks 
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
	# Now check for minimum free space - FIXME: 128MB are not good to be hard coded
	neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
	if [ "$deviceblocks" -lt "$neededblocks" ] ; then
		# Try without swap:
		swapblocks=1
		neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
		if [ "$deviceblocks" -lt "$neededblocks" ] ; then
			# Try without encrypted /home
			hcminblocks=0
			hcmaxblocks=0 
			neededblocks=` expr $isoblocks + $isoblocks + $bootblocks + $hcminblocks + $blobblocks + $swapblocks + 16 `
			if [ "$deviceblocks" -lt "$neededblocks" ] ; then
				[ "$ultraquiet" -lt 3 ] && echo "===> FAILED. Device too small." > /dev/tty8
				echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
				[ "$ultraquiet" -lt 3 ] && chvt 1
				return 1
			fi
		fi
	fi
	
	# Delete some MB at the end of the disk to remove remaining GUID backup table
	dd if=/dev/zero of=$device bs=8388608 seek=` expr $deviceblocks - 4 ` 2>/dev/null
	
	# Copy license information that might be hidden
	dd if=$device of=/tmp/license.bin bs=1024 skip=2 count=1 
	
	# Let the games begin...
	umount /lesslinux/cdrom
	
	[ "$ultraquiet" -lt 3 ] && echo '---> Creating partition table and bootloader' > /dev/tty8
	[ "$ultraquiet" -gt 1 ] && genericpgbar 0 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/05driveconf.ppm
	
	# Recalculate the possible size of the partition for the encrypted home container
	hcblocks=1
	if [ "$homecontmax" -gt 0 ] ; then
		hcmaxblocks=` expr $homecontmax / 8 ` 
		hcminblocks=` expr $homecontmin / 8 ` 
		hcpossible=` expr $deviceblocks - $isoblocks - $isoblocks - $bootblocks - $blobblocks - $swapblocks - 40 ` 
		if [ "$hcpossible" -gt $hcmaxblocks ] ; then
			hcblocks=$hcmaxblocks
		else
			hcblocks=$hcpossible
		fi
	fi
	
	# Create a single FAT32 partition holding legacy and EFI boot files
	freespacestart=` expr '(' $deviceblocks - $isoblocks - $swapblocks - $hcblocks - $blobblocks - 2 ')' '*' 8388608 `
	partstart=`      expr '(' $isoblocks + 2 ')' '*' 8388608 `
	# Now overwrite the start of the device
	dd if="$device" bs=512 count=1 of=/tmp/isohybrid.mbr 
	dd if=/dev/zero bs=512 count=1 of="$device"
	parted -s $device unit B mklabel msdos
	sync
	mdev -s
	
	# Single partition - data, legacy boot, EFI boot
	parted -s $device unit B mkpart primary fat32 $partstart ` expr $freespacestart - 1 `  
	parted -s $device unit B set 1 boot on
	parted -s $device unit B set 1 esp on
	sync
	
	# Restore the license information
	dd if=/tmp/license.bin of=$device bs=1024 seek=2 count=1
	sync
	
	[ "$ultraquiet" -gt 1 ] && genericpgbar 10 32 "$convert_head" "${convert_mkfs}" "" tty1
	[ -p /splash.fifo ] && echo 10 > /splash.fifo
	[ -b ${device}1 ] && dd if=/dev/zero bs=1M count=8 of=${device}1
	mkfs.vfat -n USBDATA "${device}1"
	cat /etc/syslinux/mbr.bin > "$device"
	mkdir -p /lesslinux/boot
	mkdir -p /lesslinux/efiboot
	mount -t vfat -o rw "${device}1" /lesslinux/boot
	mkdir -p /lesslinux/boot/boot
	cp -v /tmp/isohybrid.mbr /lesslinux/boot/boot
	touch /lesslinux/boot/boot/dontconvert
	stickloop=` losetup -f ` 
	losetup -r ${stickloop} ${device} 
	mount -t iso9660 -o ro "${stickloop}" /lesslinux/cdrom
	newuuid=` blkid.static -o udev "${device}1" | grep 'ID_FS_UUID=' | awk -F '=' '{print $2}' ` 
	
	# Copy legacy boot files
	tar -C /lesslinux/cdrom -cf - boot | tar -C /lesslinux/boot -xf -
	touch /lesslinux/boot/boot/cmdline
	cp -v /tmp/legacy.mbr /lesslinux/boot
	# Copy GRUBs file to properly detect the boot partition
	idfile=` ls /lesslinux/boot/boot/grub/????????.cd `
	idtarg=` echo $idfile | sed 's/\.cd/.pt/g' ` 
	mv $idfile $idtarg
	
	# Copy EFI boot files
	# Copy EFI boot image
	if [ -f /lesslinux/cdrom/boot/efi/efi.img ] ; then
		efiloop=` losetup -f `
		losetup $efiloop /lesslinux/cdrom/boot/efi/efi.img
		mount -t vfat -o ro $efiloop /lesslinux/efiboot
		tar -C /lesslinux/efiboot -cvf - . | tar -C /lesslinux/boot -xf -
		# Modify EFI boot files
		find /lesslinux/boot/loader -type f -name '*.usb' | while read cfgfile ; do 
			outfile=` echo ${cfgfile} | sed 's/\.usb$/.conf/g' `
			cp -v ${cfgfile} ${outfile} 
		done
		find /lesslinux/boot/loader -type f -name '*.conf' | while read cfgfile ; do 
			[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
			sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
			[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
			[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
			[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
		done
		if [ -f /lesslinux/boot/boot/grub/grub.cfg ] ; then
			if [ -f /lesslinux/boot/boot/grub/uninstall.cfg ] ; then
				cat /lesslinux/boot/boot/grub/uninstall.cfg >> /lesslinux/boot/boot/grub/grub.cfg
			fi
			find /lesslinux/boot/boot/grub -type f -name '*.cfg' | while read cfgfile ; do
				sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
				[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
				[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
				[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
			done
		fi
		sync
		umount /lesslinux/efiboot
		losetup -d $efiloop
	fi
	
	# Modify legacy boot files
	find /lesslinux/boot/boot/isolinux -type f -name '*.cfg' | while read cfgfile ; do 
		[ -f "${cfgfile}.${lang}" ] && cp "${cfgfile}.${lang}" "${cfgfile}"
		sed -i 's/uuid=all/uuid='"${newuuid}"'/g' "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  "${cfgfile}"
		[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' "${cfgfile}"
		[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    "${cfgfile}"
		sed -i 's%^INCLUDE /boot/isolinux/boot0x80.cfg%# INCLUDE /boot/isolinux/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^MENU INCLUDE /boot/isolinux/\([a-z]*\)/boot0x80.cfg%# MENU INCLUDE /boot/isolinux/\1/boot0x80.cfg%g' "${cfgfile}"
		sed -i 's%^# INCLUDE /boot/isolinux/usbonly%INCLUDE /boot/isolinux/usbonly%g' "${cfgfile}" 
		sed -i 's%^# INCLUDE /boot/isolinux/\([a-z]*\)/usbonly%INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
		sed -i 's%^# MENU INCLUDE /boot/isolinux/\([a-z]*\)/usbonly% MENU INCLUDE /boot/isolinux/\1/usbonly%g' "${cfgfile}" 
	done
	cfg=/lesslinux/boot/boot/isolinux/isolinux.cfg
	[ -f /lesslinux/boot/boot/isolinux/extlinux.conf ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.conf
	[ -f /lesslinux/boot/boot/isolinux/extlinux.conf.${lang} ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.conf.${lang}
	[ -f /lesslinux/boot/boot/isolinux/extlinux.cfg ] && cfg=/lesslinux/boot/boot/isolinux/extlinux.cfg
	[ "$cfg" '!=' /lesslinux/boot/boot/isolinux/extlinux.conf ] && cp "$cfg" /lesslinux/boot/boot/isolinux/extlinux.conf
	sed -i 's/uuid=all/uuid='"${newuuid}"'/g' /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=all/crypt='"${cryptuuid}"'/g'  /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$hcblocks"   -gt 1 ] && sed -i 's/crypt=none/crypt='"${cryptuuid}"'/g' /lesslinux/boot/boot/isolinux/extlinux.conf
	[ "$swapblocks" -gt 1 ] && sed -i 's/swap=none/swap='"${swapuuid}"'/g'    /lesslinux/boot/boot/isolinux/extlinux.conf

	echo -n "${newuuid}" > /lesslinux/boot/boot/boot.uuid
	extlinux --install /lesslinux/boot/boot/isolinux
	
	tar -C /lesslinux/cdrom -cf - Manual autorun.usb GPL.txt license | tar -C  /lesslinux/boot -xvf -
	mv /lesslinux/boot/autorun.usb /lesslinux/boot/autorun.inf
	mv /lesslinux/boot/efi.sha /lesslinux/boot/EFI/efi.sha
	if [ -f /etc/lesslinux/branding/extrafiles.txt ] ; then
		for fname in ` cat /etc/lesslinux/branding/extrafiles.txt `   ; do
			tar -C /lesslinux/cdrom -cf - $fname | tar -C  /lesslinux/boot -xvf - 
		done
	fi
	if [ -f /etc/lesslinux/branding/usbpostinstall.sh ] ; then
		ash /etc/lesslinux/branding/usbpostinstall.sh /lesslinux/boot
	fi
	
	umount /lesslinux/boot
	
	echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
	echo -n "${stickloop}" > /var/run/lesslinux/install_source
	echo "bootdevice=${stickloop}" >> /var/run/lesslinux/startup_vars
	echo "outerdevice=$device" >> /var/run/lesslinux/startup_vars
	echo "${device}" > /var/run/lesslinux/preppartitions
	[ "$ultraquiet" -lt 3 ] && echo "===> Done." > /dev/tty8
	[ "$ultraquiet" -lt 3 ] && chvt 1
	[ -p /splash.fifo ] && echo 100 > /splash.fifo
	[ -p /splash.fifo ] && fbsplash -i /etc/lesslinux/fbsplash_text.cfg -s /etc/lesslinux/branding/fbsplash/textblank.ppm	
}

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
	if [ "$filesystem" = "ext2" -o "$filesystem" = "ext3" -o "$filesystem" = "ext4" ] ; then
	    mount -o ro -t ext4 $device /lesslinux/cdrom 2>/dev/null
	#elif [ "$filesystem" = "ntfs" ] ; then
	#    if [ -f /static/sbin/ntfs-3g.static -a "$ntfsrw" -gt 0 ] ; then
	#	ntfs-3g.static -o rw $device /lesslinux/cdrom 2>/dev/null
	#    elif [ -f /static/sbin/ntfs-3g.static ] ; then
	#	ntfs-3g.static -o ro $device /lesslinux/cdrom 2>/dev/null
	#    else
	#	mount -t $filesystem -o ro $device /lesslinux/cdrom 2>/dev/null
	#    fi
	else
	    mount -t $filesystem -o ro $device /lesslinux/cdrom 2>/dev/null
	fi
	thatversion=` cat /lesslinux/cdrom/${contdir}/version.txt ` 2>/dev/null
	if [ "$thisversion" = "$thatversion" ] ; then
		touch /var/run/lesslinux/cdfound
		echo -n "$device" > /var/run/lesslinux/install_source
		echo "bootdevice=$device" > /var/run/lesslinux/startup_vars
		echo "bootmode=plain" >> /var/run/lesslinux/startup_vars
		if ( echo "$device" | grep -E  'd[a-z]$' > /dev/null 2>&1 ) && \
		   ( cat /proc/mounts | grep "$device" | grep "iso9660" > /dev/null 2>&1 ) ; then
			doconvert=1
			umount /lesslinux/cdrom 
			mkdir -p /lesslinux/boot 
			mount -o ro ${device}1 /lesslinux/boot
			if [ -f /lesslinux/boot/boot/dontconvert ] ; then
				doconvert=0
			fi
			umount /lesslinux/boot
			if echo "$skipservices" | grep -q '|convertiso|' ; then
				doconvert=0
			fi
			if [ "$doconvert" -lt 1 ]  ; then
				umount /lesslinux/cdrom 
				stickloop=` losetup -f ` 
				losetup -r ${stickloop} ${device}
				mount ${stickloop} /lesslinux/cdrom 
				echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
				echo -n "$stickloop" > /var/run/lesslinux/install_source
				echo "bootdevice=$stickloop" >> /var/run/lesslinux/startup_vars
				echo "outerdevice=$device" >> /var/run/lesslinux/startup_vars
			elif grep -q noparttablehack /proc/cmdline ; then
				mount -t $filesystem -o ro $device /lesslinux/cdrom
				iso_gpt_convert "$device"
			else
				mount -t $filesystem -o ro $device /lesslinux/cdrom
				iso_hack_convert "$device"
			fi
		else
			echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
		fi
	elif mountpoint -q /lesslinux/cdrom ; then
		if [ "$skiploop" -lt "1" ] ; then
			mkdir -p /lesslinux/isoloop
			find /lesslinux/cdrom -type f -name '*.iso' -maxdepth 3 | while read isofile ; do
				printf "$bold...> Checking ISOLOOP $isofile $normal\n"
				free_loop=` losetup -f `
				losetup $free_loop "$isofile"
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
					if [ -x /static/sbin/blkid.static ] ; then
						/static/sbin/blkid.static -o udev $device | grep UUID > /var/run/lesslinux/bootdevice.udev
						/static/sbin/blkid.static -o udev $device | grep FS_TYPE >> /var/run/lesslinux/bootdevice.udev
						chmod 0755 /var/run/lesslinux/bootdevice.udev
					fi
					if ( echo "$device" | grep -E  '/dev/sd[a-z]$' > /dev/null 2>&1 ) && \
					   ( cat /proc/mounts | grep "$device" | grep "iso9660" > /dev/null 2>&1 ) ; then
			                    echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
					else
					    echo "isohybrid=false" >> /var/run/lesslinux/startup_vars
			                fi
					overlay=` echo -n "$isofile" | sed 's/iso$/tgz/g' `
					[ -f "$overlay" ] && cp "$overlay" /etc/lesslinux/branding/overlays/overlay7.tgz  
				else
					umount /lesslinux/isoloop > /dev/null 2>&1
					losetup -d $free_loop > /dev/null 2>&1
				fi
			done
		fi
	fi
	[ -f /var/run/lesslinux/cdfound ] || umount /lesslinux/cdrom 2>/dev/null
	if [ -f /var/run/lesslinux/cdfound ] ; then
		printf "$bold...> Found system $normal\n"
	elif [ "$filesystem" = iso9660 ] ; then
		# Check the partitioning for free space beyond the partition
		pend=` parted -s -m "$device" unit b print | tail -n1 | awk -F ':' '{print $3}' | sed 's/B//g' ` 
		if [ "$pend" -gt 0 ] ; then
			# Check if there is enough space behind the partition table for another ISO image
			devsize=`     parted -m -s ${device} unit b print | grep msdos | awk -F ':|B:' '{print $2}' ` 
			partend=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $3}'  `
			isosize=`     parted -m -s ${device} unit b print | grep '^1'  | awk -F ':|B:' '{print $2}'  `
			isotwostart=` expr $devsize - $isosize - 8388608 ` 
			# Exit gracefully if size is not sufficient
			if [ "$isotwostart" -lt "$partend" ] ; then
				printf "$bold...> Not enough space for secondary ISO on ${device} $normal\n"
			else
				# Determine the end of our new loop device by matching an 8M chunk towards the end of the device: 
				loopendblock=` expr '(' $devsize - $isosize ')' / 8388608 - 1 ` 
				# Create a loop device with correct parameters 
				nextloop=` losetup -f ` 
				losetup -o ` expr $loopendblock '*' 8388608 ` $nextloop $device
				mount -t $filesystem -o ro $nextloop /lesslinux/cdrom 2>/dev/null
				thatversion=` cat /lesslinux/cdrom/${contdir}/version.txt ` 2>/dev/null
				if [ "$thisversion" = "$thatversion" ] ; then
					touch /var/run/lesslinux/cdfound
					echo "bootmode=plain" >> /var/run/lesslinux/startup_vars
					echo "isohybrid=true" >> /var/run/lesslinux/startup_vars
					echo -n "$stickloop" > /var/run/lesslinux/install_source
					echo "bootdevice=$stickloop" >> /var/run/lesslinux/startup_vars
					echo "outerdevice=$device" >> /var/run/lesslinux/startup_vars
					echo "loopoffset=$loopoffset" >> /var/run/lesslinux/startup_vars
				else
					umount /lesslinux/cdrom 2>/dev/null
					losetup -d $nextloop
				fi
			fi
		fi
	fi
}

case $1 in
    start)
	if grep earlyeject /proc/cmdline ; then
	    for n in `seq 0 9 ` ; do
	        eject /dev/sr${n}
	    done
	fi
        if [ -f /var/run/lesslinux/cdfound ] ; then
	    printf "$bold===> Skip search for LESSLINUX System $normal\n"
	else
	    printf "$bold===> Searching for LESSLINUX System $normal\n"
	    mkdir -p /lesslinux/cdrom
	    ## [ "$usbsettle" -gt 1 ] && sleep $usbsettle && mdev -s
	    alreadychecked=""
	    skipisos=0
	    if echo "$skipsearch" | grep -q '|isoloop|' ; then
		skipisos=1
	    fi
	    
	    ##
	    ## First try to find our system device by blkid.static - Installers should write
	    ## the uuid of the system partition to the syslinux.cfg files to speed up
	    ## the boot!
	    ##
	    
	    if [ '!' "$uuid" = all -a -n "$uuid" -a -f /static/sbin/blkid.static ] ; then
	        for i in ` seq $usbwait ` ; do
			if [ '!' -f /var/run/lesslinux/cdfound ] ; then
				devname=` blkid.static -U $uuid `
				fstype=` blkid.static -o udev $devname | grep 'ID_FS_TYPE=' | awk -F '=' '{print $2}' `
				alreadychecked="$alreadychecked  $devname "
				case $fstype in 
					ext*)
						mount_and_check $devname ext4 $skipisos
						# A ext2/3/4 boot file system might also indicate that the system itself
						# resides on a higher partition that is dd'ed with the ISO - try em
						masterdev=` echo -n "$devname" | sed 's/[0-9]*$//g' ` 
						for p in  9 8 7 6 5 4 3 2 1 ` seq 10 31 ` ; do
							mount_and_check ${masterdev}${p} iso9660 $skipisos
						done
						mkdir -p /lesslinux/boot
						[ -f /var/run/lesslinux/cdfound ] && mount -t ext4 -o ro "$devname" /lesslinux/boot 
					;;
					btrfs*)
						mount_and_check $devname btrfs $skipisos
					;;
					exfat*)
						printf "$bold...> Sorry, exfat is not supported yet $normal\n"
					;;
					vfat*)
						mount_and_check $devname vfat $skipisos
					;;
					ntfs*)
						if [ "$skipntfs" -gt 0 ] ; then
							printf "$bold...> Skipping NTFS as of user request $normal\n"
						else
							mount_and_check $devname ntfs $skipisos
						fi
					;;
					*)
						mount_and_check $devname linux $skipisos
					;;
				esac
			fi
			if [ '!' -f /var/run/lesslinux/cdfound ] ; then
				sleep 1
				mdev -s
			fi
	        done
	    fi
	    [ -f /var/run/lesslinux/cdfound ] && exit 0
	    
	    ##
	    ## Now try optical drives and USB sticks or Xen disks that use a UUID which
	    ## matches the build timestamp. Official LessLinux ISOs that are build with
	    ## xorriso will offer this feature.
	    ##
	    ## Also cover images that are directly dd'ed to a partition. Some installers
	    ## do so and ignore to update the UUID in the boot command line. This also
	    ## allows really simple installation on partitioned Xen disks.
	    ##
	    
	    isouuid=` cat /etc/lesslinux/updater/isouuid.txt ` 
	    if [ -f /static/sbin/blkid.static ] ; then
	        for i in ` seq $usbwait ` ; do
		    if [ '!' -f /var/run/lesslinux/cdfound ] && echo "$skipsearch" | grep -qv '|cddvd|' ; then
			for n in 9 8 7 6 5 4 3 2 1 0 ; do
			    testuuid=` blkid.static -o udev /dev/sr${n} | grep ID_FS_UUID= | awk -F '=' '{print $2}' ` 
			    if [ "$testuuid" = "$isouuid" ] ; then
				mount_and_check /dev/sr${n} iso9660 $skipisos
			    fi
			done
		    fi
		    if [ '!' -f /var/run/lesslinux/cdfound ] && echo "$skipsearch" | grep -qv '|nbd|' ; then
			testuuid=` blkid.static -o udev /dev/nbd0 | grep ID_FS_UUID= | awk -F '=' '{print $2}' ` 
			if [ "$testuuid" = "$isouuid" ] ; then
			    mount_and_check /dev/nbd0 iso9660 $skipisos
			fi
		    fi
		    if [ '!' -f /var/run/lesslinux/cdfound ] && echo "$skipsearch" | grep -qv '|isohybrid|' ; then
			cat /proc/partitions | awk '{print $4}' | grep -Ev 'loop|dm|[0-9]$|^$|name$' | while read devname ; do
			    testuuid=` blkid.static -o udev /dev/${devname} | grep ID_FS_UUID= | awk -F '=' '{print $2}' ` 
			    if [ "$testuuid" = "$isouuid" ] ; then
				mount_and_check /dev/${devname} iso9660 $skipisos
			    fi	
			done
		    fi
		    if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			cat /proc/partitions | awk '{print $4}' | grep -E '(xv|s|v)d[a-z][0-9]+$' | while read devname ; do
			    testuuid=` blkid.static -o udev /dev/${devname} | grep ID_FS_UUID= | awk -F '=' '{print $2}' ` 
			    if [ "$testuuid" = "$isouuid" ] ; then
				mount_and_check /dev/${devname} iso9660 $skipisos
			    fi	
			done
		    fi
		    if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			sleep 1
			mdev -s
		    fi
		done
	    fi
	    [ -f /var/run/lesslinux/cdfound ] && exit 0
	    
	    ##
	    ## Then try optical drives if they are not explicitely skipped and USB sticks
	    ## or Xen disks that are directly formatted with ISO9660. Most users will
	    ## use one of those methods.
	    ##
	    ## This will also find loopback images on UDF formatted media as used on the
	    ## DVDs of many computer magazines.
	    ##
	    
	    for i in ` seq $usbwait ` ; do
	        if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			if echo "$skipsearch" | grep -qv '|cddvd|' ; then
				for n in ` seq 0 9 ` ; do
					alreadychecked="$alreadychecked /dev/sr${n} "
					mount_and_check /dev/sr${n} iso9660 $skipisos
				done
			fi
		fi
		if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			if echo "$skipsearch" | grep -qv '|udf|' ; then
				for n in ` seq 0 9 ` ; do
					alreadychecked="$alreadychecked /dev/sr${n} "
					mount_and_check /dev/sr${n} udf $skipisos
				done
			fi
		fi
		if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			if echo "$skipsearch" | grep -qv '|isohybrid|' ; then
				cat /proc/partitions | awk '{print $4}' | grep -Ev 'loop|dm|^$|name$' | while read devname ; do
					mount_and_check /dev/${devname} iso9660 $skipisos
				done
			fi
		fi
		if [ '!' -f /var/run/lesslinux/cdfound ] ; then
			sleep 1
			mdev -s
		fi
	    done
	    [ -f /var/run/lesslinux/cdfound ] && exit 0
	    
	    ##
	    ## Then try any blockdevice that is found in /proc/partitions
	    ##
	    ## blkid.static should be present to be able to detect for 
	    ## exaple plain UDF on hard disk without partition table...
	    ## 
	    
	    if [ -f /static/sbin/blkid.static ] ; then
	        for i in ` seq $usbwait ` ; do
			cat /proc/partitions | grep -Ev 'loop|dm|name|^$' | awk '{print $4}' | while read devname ; do
				if [ '!' -f /var/run/lesslinux/cdfound ] ; then
					fstype=` blkid.static -o udev /dev/${devname} | grep 'ID_FS_TYPE' | awk -F '=' '{print $2}' `
					alreadychecked="$alreadychecked /dev/$devname "
					case $fstype in
					ext*)
						if echo "$skipsearch" | grep -v '|linux|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname ext4 $skipisos
						fi
					;;	
					btrfs*)
						if echo "$skipsearch" | grep -v '|linux|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname btrfs $skipisos
						fi
					;;
					exfat*)
						printf "$bold...> Sorry, exfat is not supported yet $normal\n"
					;;
					vfat*)
						if echo "$skipsearch" | grep -v '|vfat|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname vfat $skipisos
						fi
					;;
					iso9660*)
						if echo "$skipsearch" | grep -v '|cddvd|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname iso9660 $skipisos
						fi
					;;
					udf*)
						if echo "$skipsearch" | grep -v '|udf|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname udf $skipisos
						fi
					;;
					ntfs*)
						if echo "$skipsearch" | grep -v '|ntfs|' > /dev/null 2>&1 ; then
							mount_and_check /dev/$devname ntfs $skipisos
						fi
					;;
					esac
				fi
			done
			[ -f /var/run/lesslinux/cdfound ] || sleep 1
		done
	    fi
	    [ -f /var/run/lesslinux/cdfound ] && exit 0
	fi
    ;;
esac
		
# The end	
