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
		
case $1 in
    start)
        [ '!' -f  /var/run/lesslinux/cdfound ] && \
	    printf "$bold===> Prerequisite for LESSLINUX containers not available         $failed $normal\n" && \
	    exit 1
	if mountpoint /lesslinux/cdrom > /dev/null 2>&1 ; then
            printf "$bold===> Searching for LESSLINUX containers $normal\n"
 	    if [ "$mem_avail" -gt "$toram" ] 2> /dev/null ; then
	        printf "$bold===> Copying LESSLINUX containers to RAM $normal\n"
	        mkdir -p /lesslinux/toram/$contdir
	        cp /lesslinux/cdrom/$contdir/* /lesslinux/toram/$contdir/
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
	        umount /lesslinux/cdrom
		[ "$ejectcd" -gt 0 ] && grep -q /dev/sr /var/run/lesslinux/install_source && eject ` cat /var/run/lesslinux/install_source ` 
	        mediadir=toram
	    else
		if [ "$skipcheck" -lt 1 ] ; then
	            if ( cd /lesslinux/cdrom/$contdir/ ; sha1sum -c squash.sha ) ; then
	                printf "$bold---> Check of squash containers succeeded $normal\n"
	            else
                        printf "$bold---> Check of squash containers...                               $failed $normal\n"
	                printf "$bold     Press ENTER to continue $normal \n"
	                read nix
	            fi
	            if ( cd /lesslinux/cdrom/boot/isolinux/ ; sha1sum -c /lesslinux/cdrom/$contdir/boot.sha ) ; then
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
	mount -t tmpfs -o mode=0755 tmpfs /lib/modules
	release=` uname -r `
	mkdir /lib/modules/$release
	modcontainer=` grep -E "^${release}"' ' /lesslinux/$mediadir/$contdir/modules.txt | awk '{print $2}' `
	mount -o loop,ro /lesslinux/$mediadir/$contdir/$modcontainer /lib/modules/$release
    ;;
esac
		
# The end	
