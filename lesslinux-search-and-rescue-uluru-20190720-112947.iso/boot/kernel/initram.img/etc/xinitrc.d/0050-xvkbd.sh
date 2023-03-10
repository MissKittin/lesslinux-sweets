#!/bin/bash
		
#lesslinux provides xvkbd
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	# Set DPI value 
	if [ -f /home/surfer/.lesslinux/xvkbd.xrdb ] ; then
		xrdb -merge /home/surfer/.lesslinux/xvkbd.xrdb
	else
		mkdir -p /home/surfer/.lesslinux
		[ "$lang" = de ] && \
			echo 'xvkbd.customization: -german' >> /home/surfer/.lesslinux/xvkbd.xrdb
		[ "$lang" = fr ] && \
			echo 'xvkbd.customization: -french' >> /home/surfer/.lesslinux/xvkbd.xrdb
		[ "$lang" = es ] && \
			echo 'xvkbd.customization: -spanish' >> /home/surfer/.lesslinux/xvkbd.xrdb
		[ "$lang" = ru ] && \
			echo 'xvkbd.customization: -russian' >> /home/surfer/.lesslinux/xvkbd.xrdb
		[ "$lang" = pt ] && \
			echo 'xvkbd.customization: -portuguese' >> /home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd*Font: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd.generalFont: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd.letterFont: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd.specialFont: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd.keypadFont: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		echo 'xvkbd.banner: -misc-fixed-medium-r-semicondensed--0-0-75-75-c-0-iso8859-1' >> \
			/home/surfer/.lesslinux/xvkbd.xrdb
		xrdb -merge /home/surfer/.lesslinux/xvkbd.xrdb	
	fi
    ;;
esac

		
