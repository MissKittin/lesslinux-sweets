#!/static/bin/ash
		
#lesslinux provides modfix
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Re-loading some modules $normal\n"
	# rt61 sometimes does not load correctly with kernel 2.6.33
	# just reload it
	if lsmod | awk '{print $1}' | grep -q rt61pci ; then
		modprobe -rv rt61pci
		modprobe -v rt61pci
	fi
    ;;
esac

# The end	
