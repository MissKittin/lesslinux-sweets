#!/static/bin/ash

#lesslinux provides mountcontainer
#lesslinux patience
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
mem_avail=` cat /proc/meminfo | grep MemTotal | awk '{print $2}' `
mediadir=cdrom
kversion=` uname -r `
		
case $1 in
    start)
	# Remove the loop device for the modules first
        if [ -f /lesslinux/modules/${kversion}.sqs ] && mountpoint -q /lib/modules/${kversion} ; then
	    modloop=` cat /proc/mounts | grep "/lib/modules/${kversion}" | awk '{print $1}' `
	    umount "/lib/modules/${kversion}"
	    losetup -d ${modloop}
        fi
        [ '!' -f  /var/run/lesslinux/cdfound ] && \
	    printf "$bold===> Prerequisite for LESSLINUX containers not available         $failed $normal\n" && \
	    exit 1
	if mountpoint /lesslinux/cdrom || [ -n "$wgetiso" ] > /dev/null 2>&1 ; then
            printf "$bold===> Searching for LESSLINUX containers $normal\n"
	    if [ -f /var/run/lesslinux/isoloop ] ; then
		copy_source=/lesslinux/isoloop/$contdir
		mediadir=isoloop
	    else
		copy_source=/lesslinux/cdrom/$contdir
	    fi
	    
	    # toram=0 : never copy to RAM
	    # toram=1 : always copy to RAM
	    # toram=n : copy to RAM if available memory is larger than n kilobytes
	    copy_toram="false"
	    if [ "$mem_avail" -gt "$toram" ] && [ -z "$wgetiso" ] && [ "$toram" -gt 1 ] ; then
		copy_toram="true"
	    elif [ "$toram" -eq 1 ] && [ -z "$wgetiso" ] ; then
		copy_toram="true"
	    fi
 	    if [ "$copy_toram" = "true" ] ; then
	        printf "$bold===> Copying LESSLINUX containers to RAM $normal\n"
	        mkdir -p /lesslinux/toram/$contdir
	        cp $copy_source/* /lesslinux/toram/$contdir/
		if [ -n "$toramdirs" ] ; then
		    sepdirs=` echo "$toramdirs" | sed 's%|% %g' `
		    cdir=` dirname $copy_source ` 
		    for dir in $sepdirs ; do
			tar -C "$cdir" -cvf - "$dir" | tar -C /lesslinux/toram -xf - 
		    done
		fi
	        # Check SHA1
	        if [ "$skipcheck" -lt 1 ] ; then
		    if ( cd /lesslinux/toram/$contdir/ ; sha1sum -c squash.sha ) ; then
		        printf "$bold---> Check of squash containers succeeded $normal\n"
	            else
                        printf "$bold---> Check of squash containers...                               $failed $normal\n"
	                printf "$bold     Press ENTER to continue $normal \n"
	                read nix
	            fi
		    if ( cd /lesslinux/cdrom/boot/isolinux/ ; sha1sum -c /lesslinux/toram/$contdir/boot.sha ) ; then
	                printf "$bold---> Check of boot files succeeded $normal\n"
	            else
                        printf "$bold---> Check of boot files...                                      $failed $normal\n"
	                printf "$bold     Press ENTER to continue $normal \n"
	                read nix
	            fi
	        fi
		if [ -f /var/run/lesslinux/isoloop ] ; then
		    umount /lesslinux/isoloop
		    losetup -d ` cat /var/run/lesslinux/install_source ` 
		fi
	        umount /lesslinux/cdrom
		[ "$ejectcd" -gt 0 ] && grep -q /dev/sr /var/run/lesslinux/install_source && eject ` cat /var/run/lesslinux/install_source ` 
	        mediadir=toram
	    else
		if [ "$skipcheck" -lt 1 ] ; then
	            if ( cd /lesslinux/$mediadir/$contdir/ ; sha1sum -c squash.sha ) ; then
	                printf "$bold---> Check of squash containers succeeded $normal\n"
	            else
                        printf "$bold---> Check of squash containers...                               $failed $normal\n"
	                printf "$bold     Press ENTER to continue $normal \n"
	                read nix
	            fi
	            if ( cd /lesslinux/$mediadir/boot/isolinux/ ; sha1sum -c /lesslinux/$mediadir/$contdir/boot.sha ) ; then
	                printf "$bold---> Check of boot files succeeded $normal\n"
	            else
                        printf "$bold---> Check of boot files...                                      $failed $normal\n"
	                printf "$bold     Press ENTER to continue $normal \n"
	                read nix
	            fi
	        fi
	    fi
	fi
	cat /lesslinux/$mediadir/$contdir/mount.txt | while read fs
	do
	    mdev -s
	    case $fs in
		'#'*|'')
			true
		;;
		*)
		    container=` echo $fs | awk '{print $1}' `
		    if [ -n "$container" ] ; then
		        mountpoint=` echo $fs | awk '{print $2}' `
			mkdir -p $mountpoint > /dev/null 2>&1
			if [ "$security" = "smack" ] ; then
				if [ "$container" = "opt.sqs" ] ; then
					smackopts=',smackfsdef=internet,smackfsroot=internet'
				elif [ "$container" = "usrbin.sqs" ] ; then
					smackopts=',smackfsdef=usrbin,smackfsroot=usrbin'
				elif [ "$container" = "lib.sqs" ] ; then
					[ -d /lib/firmware ] && rm -rf /lib/firmware  
					smackopts=''
				else
					smackopts=''
				fi
				mount -o loop,ro,"$smackopts" /lesslinux/$mediadir/$contdir/$container $mountpoint
			else
				mount -o loop,ro /lesslinux/$mediadir/$contdir/$container $mountpoint
			fi
		    fi
		;;
	    esac
	done
	release=` uname -r `
	modcontainer=` grep -E "^${release}"' ' /lesslinux/$mediadir/$contdir/modules.txt | awk '{print $2}' `
	mountpoint -q /lib && mount -t tmpfs -o mode=0755 tmpfs /lib/modules
	[ -d /lib/modules/$release ] || mkdir /lib/modules/$release
	if [ -f /lesslinux/$mediadir/$contdir/$modcontainer ] ; then
	    mount -o loop,ro /lesslinux/$mediadir/$contdir/$modcontainer /lib/modules/$release
	    [ -f /lesslinux/modules/$release ] && rm /lesslinux/modules/$release
	else
	    free_loop=` losetup -f `
	    losetup $free_loop /lesslinux/modules/${release}.sqs
	    mount -t squashfs $free_loop /lib/modules/${release}
        fi
    ;;
esac
		
# The end	
