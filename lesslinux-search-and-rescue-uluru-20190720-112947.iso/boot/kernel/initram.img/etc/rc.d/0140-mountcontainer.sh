#!/static/bin/ash

#lesslinux provides mountcontainer
#lesslinux patience
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/rc.subr/progressbar
		
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
	# Same for firmware
	if [ -f /lesslinux/modules/firmware.sqs ] && mountpoint -q /lib/firmware ; then
	    firmloop=` cat /proc/mounts | grep "/lib/firmware" | awk '{print $1}' `
	    umount "/lib/firmware"
	    losetup -d ${firmloop}
        fi
        if [ '!' -f  /var/run/lesslinux/cdfound ] ; then
	    printf "$bold===> Prerequisite for LESSLINUX containers not available         $failed $normal\n"
	    touch /var/run/lesslinux/boot_failed
	    exit 1
	fi
	printf "$bold===> Searching for LESSLINUX containers $normal\n"
	if [ -f /var/run/lesslinux/isoloop ] ; then
	    copy_source=/lesslinux/isoloop/$contdir
	    mediadir=isoloop
	else
	    copy_source=/lesslinux/cdrom/$contdir
	fi
	[ "$skipcheck" -lt 1 ] && run_self_test $mediadir
	[ -f /lesslinux/$mediadir/$contdir/overlay.tgz ] && \
	    ln -sf /lesslinux/$mediadir/$contdir/overlay.tgz /etc/lesslinux/branding/overlays/overlay3.tgz
	cat /lesslinux/$mediadir/$contdir/mount.txt | while read fs
	do
	    mdev -s
	    case $fs in
		'#'*|'')
			true
		;;
		fullsys.sqs*)
		    container=` echo $fs | awk '{print $1}' `
		    mkdir -p /lesslinux/fullsys
		    mount -o loop,ro /lesslinux/$mediadir/$contdir/$container /lesslinux/fullsys
		    for d in bin lib opt sbin usr srv ; do
			mkdir -p /$d 
			[ -d /lesslinux/fullsys/$d ] && mount --bind /lesslinux/fullsys/$d /$d 
		    done
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
	    free_loop=` losetup -f `
	    losetup $free_loop /lesslinux/modules/firmware.sqs
	    mount -t squashfs $free_loop /lib/firmware
        fi
    ;;
esac
		
# The end	
