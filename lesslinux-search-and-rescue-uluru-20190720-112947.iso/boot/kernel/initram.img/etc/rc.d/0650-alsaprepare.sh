#!/static/bin/ash
		
#lesslinux provides sound2
#lesslinux license BSD
#lesslinux description
# Load some alsa modules

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Preparing sound $normal"
	udevadm control --reload-rules
	udevadm trigger --verbose --subsystem-match sound 
    ;;
esac

# END		
