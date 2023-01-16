#!/static/bin/ash
		
#lesslinux provides uninstall
#lesslinux license BSD		
#lesslinux silent

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
	start)
		if grep -q ' uninstall=full' /proc/cmdline && [ '!' "$uuid" = "all" ] && [ -n "$uuid" ] ; then 
			for i in ` seq $usbwait ` ; do
				devname=` blkid.static -U $uuid `
				if [ -n "$devname" ] ; then
					chvt 8
					echo "===> Uninstalling LessLinux, converting drive to single partition FAT32" > /dev/tty8
					echo "     Please be patient." > /dev/tty8
					fulldev=` echo "$devname" | sed 's/[0-9]$//g' `
					devicesize=` parted -sm $fulldev unit B print | head -n2 | tail -n1 | awk -F ':' '{print $2}' | sed 's/B//' `
					partstart=` expr 63 '*' 512 ` 
					partend=` expr $devicesize - 1048577 `
					if [ -n "$fulldev" ] ; then
						echo "     Delete partition table and create new partition." > /dev/tty8
						dd if=/dev/zero bs=1048576 count=1 of="$fulldev"
						parted -s $fulldev unit B mklabel msdos
						parted -s $fulldev unit B mkpart primary fat32 $partstart $partend
						parted -s $fulldev unit B set 1 lba  on
						sleep 5
						mdev -s 
						sleep 5
						echo "     Write file system." > /dev/tty8
						if [ -x /static/sbin/mkntfs.static ] ; then
							mkntfs.static -F -Q -L USBDATA "${fulldev}1"
						else
							mkfs.vfat -n USBDATA "${fulldev}1"
						fi
						sync 
						echo "     Poweroff." > /dev/tty8
						poweroff 
					fi
				else
					sleep 5
				fi
			done
		fi
	;;
esac
		
		
