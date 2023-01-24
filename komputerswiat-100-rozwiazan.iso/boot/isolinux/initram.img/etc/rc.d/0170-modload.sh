#!/static/bin/ash
		
#lesslinux provides modload
#lesslinux license BSD
#lesslinux description
# Load modules for USB and PCI devices

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Loading additional drivers $normal"
	mountpoint /proc/bus/usb || mount -t usbfs usbfs /proc/bus/usb
	/usr/bin/llmodloader.rb
	modprobe -v sr_mod
	modprobe -v fuse
	mdev -s
    ;;
esac

# END		
