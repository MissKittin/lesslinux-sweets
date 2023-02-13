#!/static/bin/ash

PATH=/static/bin:/static/sbin:/bin:/sbin

if [ '!' -L /proc/mounts ] ; then
    mount -t proc none /proc > /dev/null 2>&1
fi

. /etc/rc.conf
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
	start)
		printf "$bold===> Mounting some filesystems\n"
		# Mount /proc
		if grep '/proc' /proc/mounts > /dev/null 2>&1 ; then
			printf "$bold---> Skipping /proc, already mounted\n"
		else
			printf "$bold---> Setting up /proc                                            "
			if mount -t proc none /proc > /dev/null 2>&1 ; then
				printf "$success"
			else
				printf "$failed"
			fi
		fi
		# Mount /sys
		if grep '/sys' /proc/mounts > /dev/null ; then
			printf "$bold---> Skipping /sys, already mounted\n"
		else     
			printf "$bold---> Setting up /sys                                             "
			if mount -t sysfs none /sys > /dev/null 2>&1 ; then
				printf "$success"
			else
				printf "$failed"
			fi
		fi
		# Use mdev to populate /dev
		if [ $mdev -gt 0 ] ; then
			printf "$bold---> Setting up /dev                                             "
			sleep 3
			if mdev -s ; then
				printf "$success"
			else
				printf "$failed"
			fi
		else
			printf "$bold---> Skipping mdev, using a static /dev\n"
		fi
	;;
esac

