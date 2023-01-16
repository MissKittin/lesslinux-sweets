#!/static/bin/ash
		
#lesslinux provides gparted
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
	printf "$bold===> Adjusting sudo for GParted $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0506-gparted.sh' >> /etc/sudoers
	if check_lax_sudo ; then
	    echo 'surfer  ALL = NOPASSWD: /usr/sbin/gparted' >> /etc/sudoers
	else
	    echo 'surfer  ALL = /usr/sbin/gparted' >> /etc/sudoers
	fi
    ;;
esac

		
