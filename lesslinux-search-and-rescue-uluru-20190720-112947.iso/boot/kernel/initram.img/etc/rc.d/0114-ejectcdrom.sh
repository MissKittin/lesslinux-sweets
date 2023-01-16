#!/static/bin/ash
		
#lesslinux provides eject
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
        if [ "$ejectonumass" -gt 0 ] ; then
	    volid=` echo "$searchiso" | awk -F '|' '{print $2}' `
	    bytecount=` echo "$searchiso" | awk -F '|' '{print $3}' `
	    ddoffset=36905
	    cddevices="` ls /dev/sr[0-9] 2> /dev/null `"
	    for cddev in $cddevices ; do 
	        ddvolid=` dd if=$cddev bs=1 skip=$ddoffset count=$bytecount 2> /dev/null `
	        [ "$volid" = "$ddvolid" ] && \
		    [ -f /var/run/lesslinux/usbfound ] && \
		    /static/bin/eject $cddev
	    done
	fi
    ;;
esac
		
