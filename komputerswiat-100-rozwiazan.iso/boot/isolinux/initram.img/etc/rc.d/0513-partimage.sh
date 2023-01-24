#!/static/bin/ash
		
#lesslinux provides partimage
#lesslinux license BSD
#lesslinux description
# Allow surfer to use wrappers PartImage

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for some wrappers $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0513-partimage.sh' >> /etc/sudoers
	if check_lax_sudo ; then
		echo 'surfer  ALL = NOPASSWD: /usr/sbin/partimage' >> /etc/sudoers
	else
		echo 'surfer  ALL = /usr/sbin/partimage' >> /etc/sudoers
	fi
    ;;
esac

		
