#!/static/bin/ash
		
#lesslinux provides tc
#lesslinux license BSD
#lesslinux description
# Allow surfer to use wrappers TrueCrypt

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for some wrappers $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0514-truecrypt.sh' >> /etc/sudoers
	if check_lax_sudo ; then
		echo 'surfer  ALL = NOPASSWD: /usr/bin/truecrypt' >> /etc/sudoers
	else
		echo 'surfer  ALL = /usr/bin/truecrypt' >> /etc/sudoers
	fi
    ;;
esac

		
