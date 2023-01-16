#!/static/bin/ash

#lesslinux provides selftest

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/rc.subr/progressbar

# Run self test

case $1 in 
    start)
	printf "$bold===> Self test boot files $normal \n"
	cd /
	sha1sum -c initramfs.sha && sha1sum -c modules.sha
	retval=$?
	if [ "$retval" -gt 0 ] ; then
		upperredbar tty1
		centertext 62 2 "Self test failed. Boot media might be damaged.
Please press c + [Enter] to continue or [Enter] to shut down." tty1
		lowerredbar tty1
		read userinput
		[ "$userinput" = "c" ] || poweroff 
	fi
    ;;
esac
#		
