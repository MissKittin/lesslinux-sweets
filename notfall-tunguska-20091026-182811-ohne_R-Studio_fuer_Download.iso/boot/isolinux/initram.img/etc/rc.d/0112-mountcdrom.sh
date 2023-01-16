#!/static/bin/ash

#lesslinux provides mountcdrom
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
				
case $1 in
    start)
        if [ -f /var/run/lesslinux/cdfound ] ; then
	    printf "$bold===> Skip search for LESSLINUX CDROM $normal\n"
	else
	    printf "$bold===> Searching for LESSLINUX CDROM $normal\n"
	    [ "$usbsettle" -gt 1 ] && sleep $usbsettle && mdev -s
            volid=` echo "$searchiso" | awk -F '|' '{print $2}' `
	    bytecount=` echo "$searchiso" | awk -F '|' '{print $3}' `
	    ddoffset=36905
	    cddevices="` ls /dev/sr[0-9] 2> /dev/null `"
	    for i in ` seq $usbwait ` ; do
	        if [ -z "$cddevices" ] ; then
	            for i in /dev/sr[0-9] ; do
	                if [ -b "$i" ] ; then
		            cddevices=$cddevices" "$i
		        fi
		    done
		    test -z "$cddevices" && printf "---> Still searching CDROM \n"
		    sleep 5 && mdev -s
		fi
	    done
            for i in $cddevices ; do
                ddvolid=` dd if=$i bs=1 skip=$ddoffset count=$bytecount 2> /dev/null `
	        if [ "$volid" = "$ddvolid" ] ; then
	            mkdir -p /lesslinux/cdrom
		    echo -n "$i" > /var/run/lesslinux/install_source
		    mount $i /lesslinux/cdrom && touch /var/run/lesslinux/cdfound
	            exit 0
	        fi
	    done
	fi
    ;;
esac
		
# The end	
