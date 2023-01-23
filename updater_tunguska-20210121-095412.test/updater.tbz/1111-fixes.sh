#!/bin/bash
                
#lesslinux provides cbfixes
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    stop)
	umount /usr/share/lesslinux/drivetools/accesspoint.rb
    ;;
esac

