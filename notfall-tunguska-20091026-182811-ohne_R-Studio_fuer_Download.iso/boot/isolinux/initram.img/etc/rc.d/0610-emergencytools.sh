#!/static/bin/ash
		
#lesslinux provides emtool
#lesslinux license BSD
#lesslinux description
# Allow surfer to use wrappers for dd, PhotoRec and TestDisk

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Adjusting sudo for some wrappers $normal\n"
	echo '' >> /etc/sudoers
	echo '# added by /etc/rc.d/0610-emergencytools.sh' >> /etc/sudoers
	if [ "$laxsudo" -gt 0 ] ; then
		echo 'surfer  ALL = NOPASSWD: /usr/bin/photorec-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /usr/bin/dc3dd-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /usr/bin/ms-sys-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /usr/bin/ddrescue-starter.rb' >> /etc/sudoers
	else
		echo 'surfer  ALL = /usr/bin/photorec-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = /usr/bin/dc3dd-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = /usr/bin/ms-sys-starter.rb' >> /etc/sudoers
		echo 'surfer  ALL = /usr/bin/ddrescue-starter.rb' >> /etc/sudoers
	fi
	mdev -s
	/usr/bin/mount_drives.rb
    ;;
esac

		