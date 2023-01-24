#!/static/bin/ash
		
#lesslinux provides gsmart
#lesslinux license BSD
#lesslinux description
# Allow surfer to use gparted

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for GSmartControl $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0511-gsmart.sh' >> /etc/sudoers
	echo 'surfer  ALL = NOPASSWD: /usr/bin/gsmartcontrol' >> /etc/sudoers
	echo 'surfer  ALL = NOPASSWD: /usr/bin/gsmartcontrol-root' >> /etc/sudoers
    ;;
esac

		
