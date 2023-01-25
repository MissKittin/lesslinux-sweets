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
	if [ -f /lesslinux/cdrom/lesslinux/mount.txt ] ; then
	    
	    # The small method for updating: 
	    #
	    # Find xdeltas and apply them
	    
	    if ls /lesslinux/cdrom/lesslinux/*.xd3 2>/dev/null ; then
		printf "$bold===> Found updates... Please be patient... $normal\n"
		mount -o remount,rw /lesslinux/cdrom
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
	    fi
	    
	    # The large method for updating:
	    #
	    # Loopback mount an ISO image
	    
	    if [ -f /lesslinux/cdrom/lesslinux/isoupd.txt ] ; then
		printf "$bold===> Found updates... Please be patient... $normal\n"
	        mount -o remount,rw /lesslinux/cdrom
		free_loop=` losetup -f `
		mkdir /lesslinux/update_iso
		mkdir /lesslinux/update_source
		update_found=0
		update_iso=""
		if [ -f /lesslinux/cdrom/update.iso ] ; then
		    update_iso=/lesslinux/cdrom/update.iso
		    losetup $free_loop /lesslinux/cdrom/update.iso
		else
		    # Try the first partition of the selected device
		    trypart=` cat /var/run/lesslinux/install_source | sed 's/2/1/g' `
		    mount -o rw $trypart /lesslinux/update_source
		    losetup $free_loop /lesslinux/update_source/update.iso
		    update_iso=/lesslinux/update_source/update.iso
		fi
		mount -t iso9660 $free_loop /lesslinux/update_iso
		thisversion=` cat /etc/lesslinux/updater/version.txt `
		thatversion=` cat /lesslinux/update_iso/lesslinux/version.txt ` 2> /dev/null
		if [ "$thisversion" = "$thatversion" ] ; then
		    if ( cd /lesslinux/update_iso/lesslinux/ ; sha1sum -c squash.sha ) ; then
		        printf "$bold---> Check of new files successful... $normal\n"
			rm /lesslinux/cdrom/lesslinux/*.sqs
		        ( cd /lesslinux/update_iso/lesslinux/ ; tar -cvf - . | tar -C /lesslinux/cdrom/lesslinux -xf - )
		        update_found=1
		    else
		        printf "$bold---> Check of new files failed... $normal\n"
			printf "$bold     Maybe drive is damaged - consider reinstallation $normal\n"
			printf "$bold     Sleeping 30 seconds $normal\n"
			sleep 30
		    fi	
		fi
		umount /lesslinux/update_iso
		losetup -d $free_loop
		if [ "$update_found" -gt 0 ] ; then
		    rm "$update_iso"
		    rm /lesslinux/cdrom/lesslinux/isoupd.txt
		fi
		mountpoint -q /lesslinux/update_source && umount /lesslinux/update_source
	    fi
	fi
    ;;
esac    

		
