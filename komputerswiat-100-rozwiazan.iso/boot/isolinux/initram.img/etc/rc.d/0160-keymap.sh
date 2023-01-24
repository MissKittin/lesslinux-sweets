#!/static/bin/ash
		
#lesslinux provides keymap
#lesslinux license BSD
#lesslinux description
# Set keymap according to choice of language

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	printf "$bold===> Setting keymap                                              "
	if [ -n "$keymap" ] && loadkeys "$keymap" > /dev/null 2>&1 ; then
	    printf "$success"
	else
	    printf "$failed"
	fi
    ;;
esac

# END		
