#!/static/bin/ash
		
#lesslinux provides testdisk
#lesslinux license BSD
#lesslinux description
# Allow surfer to use PhotoRec and TestDisk

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for PhotoRec and TestDisk $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0507-testdisk.sh' >> /etc/sudoers
	if check_lax_sudo ; then
	    echo 'surfer  ALL = NOPASSWD: /usr/sbin/testdisk' >> /etc/sudoers
	    echo 'surfer  ALL = NOPASSWD: /usr/sbin/photorec' >> /etc/sudoers
	else
	    echo 'surfer  ALL = /usr/sbin/testdisk' >> /etc/sudoers
	    echo 'surfer  ALL = /usr/sbin/photorec' >> /etc/sudoers
	fi
    ;;
esac

		
