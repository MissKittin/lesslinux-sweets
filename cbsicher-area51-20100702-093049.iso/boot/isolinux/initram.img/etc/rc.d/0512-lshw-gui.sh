#!/static/bin/ash
		
#lesslinux provides lshwgui
#lesslinux license BSD
#lesslinux description

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for lshw-gui $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0512-lshw-gui.sh' >> /etc/sudoers
	echo 'surfer  ALL = NOPASSWD: /usr/sbin/lshw' >> /etc/sudoers
	echo 'surfer  ALL = NOPASSWD: /usr/sbin/gtk-lshw' >> /etc/sudoers
    ;;
esac

		
