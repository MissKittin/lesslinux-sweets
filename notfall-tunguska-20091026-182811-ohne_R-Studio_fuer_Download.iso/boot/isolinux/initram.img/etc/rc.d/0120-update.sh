#!/static/bin/ash
		
#lesslinux provides update
#lesslinux verbose
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

grep '/dev/sr' /var/run/lesslinux/install_source > /dev/null && exit 0

case $1 in 
    start)
	if ls /lesslinux/cdrom/lesslinux/*.xd3 2>/dev/null ; then
	    printf "$bold===> Found updates... Please be patient... $normal\n"
	    mount -o remount,rw /lesslinux/cdrom
	fi
        for i in ` cat /lesslinux/cdrom/lesslinux/mount.txt | awk '{print $1}' ` ; do
	    delta=` echo $i | sed 's/\.sqs/.xd3/g' `
	    if [ -f /lesslinux/cdrom/lesslinux/$delta ] ; then
		printf "$bold---> Applying update for $i $normal\n"
	        xdelta3 -d -s /lesslinux/cdrom/lesslinux/$i /lesslinux/cdrom/lesslinux/$delta /tmp/$i && \
		    rm /lesslinux/cdrom/lesslinux/$delta && \
		    rm /lesslinux/cdrom/lesslinux/$i && \
		    cp /tmp/$i /lesslinux/cdrom/lesslinux/ && \
		    rm /tmp/$i
	    fi
	done
    ;;
esac    

		
