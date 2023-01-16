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
    printf "$bold===> Mounting some filesystems$normal\n"
    # Mount /proc
    if mountpoint /proc > /dev/null 2>&1 ; then
        true
	# do nothing
    else
	mount -t proc none /proc > /dev/null 2>&1
    fi
    # Mount /sys
    if mountpoint /sys > /dev/null 2>&1 ; then
        true
    else     
        mount -t sysfs sysfs /sys > /dev/null 2>&1
    fi
    # Mount /dev/pts
    if mountpoint /dev/pts > /dev/null 2>&1 ; then
        printf "$bold---> Skipping /dev/pts, already mounted $normal\n"
    else
        printf "$bold---> Setting up /dev/pts                                         "
        if mount -t devpts devpts /dev/pts > /dev/null 2>&1 ; then
            printf "$success"
        else
            printf "$failed"
        fi
    fi
    # Mount /dev/shm
    if mountpoint /dev/shm > /dev/null 2>&1 ; then
        printf "$bold---> Skipping /dev/shm, already mounted $normal\n"
    else
        printf "$bold---> Setting up /dev/shm                                         "
        if mount -t tmpfs devshm /dev/shm > /dev/null 2>&1 ; then
            printf "$success"
        else
            printf "$failed"
        fi
    fi
    # Mount /proc/bus/usb
    if mountpoint /proc/bus/usb > /dev/null 2>&1 ; then
	printf "$bold---> Skipping /proc/bus/usb, already mounted $normal\n"
    else
	printf "$bold---> Setting up /proc/bus/usb                                    "
	if mount -t usbfs usbfs /proc/bus/usb > /dev/null 2>&1 ; then
            printf "$success"
        else
            printf "$later"
        fi
    fi
    # Mount /tmp
    mountpoint -q /tmp || mount -t tmpfs tmpfs -o noexec,nosuid,nodev,size=${tmpsize}m /tmp
    mountpoint -q /home || mount -t tmpfs tmpfs -o mode=0755,noexec,nosuid,nodev,size=${homesize}m /home
    ln -sf /proc/mounts /etc/mtab
    # FIXME: we should move this to a separate script
    tar -C /home -xzf /etc/lesslinux/skel/surfer.tgz 
    # Change some modes
    chmod 0666 /dev/tty
    chmod 0666 /dev/pty*
  ;;
esac    
#		
