#!/bin/bash
		
#lesslinux provides gtk3theme
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Copy Adwaita theme for root $normal\n"
	mkdir -p /root/.config
	tar -C /usr/share/themes/Adwaita -cvf - gtk-3.0 gtk-2.0 | tar -C /root/.config -xf - 
    ;;
esac
		
