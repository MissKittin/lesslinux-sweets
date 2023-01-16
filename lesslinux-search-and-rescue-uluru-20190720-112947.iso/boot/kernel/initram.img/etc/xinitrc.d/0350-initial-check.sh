#!/bin/bash
		
#lesslinux provides initialcheck
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	xfsettingsd --replace
	matchbox-window-manager -force_dialogs Warnung &
	sudo /usr/bin/initial_system_check.sh 
	killall -9 matchbox-window-manager 
    ;;
esac

		
