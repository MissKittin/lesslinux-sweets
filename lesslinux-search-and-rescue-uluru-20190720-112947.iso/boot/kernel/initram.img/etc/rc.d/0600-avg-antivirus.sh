#!/bin/bash
		
#lesslinux provides avg-antivirus
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if mountpoint -q /opt/avg ; then
	    printf "$bold===> Skipping AVG, already mounted $normal\n"
	else
	    printf "$bold===> Preparing AVG $normal\n"
	    if [ -d /lesslinux/blob/avg-free ] ; then
		mkdir -p /lesslinux/blob/avg-free/dotavg
		mkdir -p /root/.avg
		mount --bind /lesslinux/blob/avg-free /opt/avg
		mount --bind /lesslinux/blob/avg-free/dotavg /root/.avg
	    elif [ -f /lesslinux/blob/avg-free.tgz ] ; then
		if mountpoint -q /lesslinux/blobpart ; then
			mkdir -p /lesslinux/blobpart/avg-free
			ln -sf /lesslinux/blobpart/avg-free /lesslinux/blob/avg-free 
			mkdir -p /lesslinux/blob/avg-free/dotavg
			mkdir -p /root/.avg
			mount --bind /lesslinux/blob/avg-free /opt/avg
			mount --bind /lesslinux/blob/avg-free/dotavg /root/.avg
		else
			mount -t tmpfs -o mode=0755,size=512M tmpfs /opt/avg
		fi
		tar -C /opt/avg -xzf /lesslinux/blob/avg-free.tgz
		retval=$?
		chown -R 0:0 /opt/avg/avg20*
		mv /opt/avg/avg20*/opt/avg/av /opt/avg/
		install -m 0644 /opt/avg/avg20*/etc/avg.conf /etc/
		rm -rf /opt/avg/avg20*
		touch -t 201301010000 /opt/avg/av/var/data/incavi.avm
		if [ -n "$DISPLAY" ] ; then
			if zenity --text-info --title 'Lizenzbedingungen AVG Antivirus' \
				--filename=/opt/avg/av/doc/license_us.txt \
				--checkbox='Ich bin mit den Lizenzbedingungen einverstanden' ; then
				echo 'OK, license accepted'
			else
				rm -rf /opt/avg/av 
				umount /opt/avg
				umount /root/.avg
				rm -rf /lesslinux/blob/avg-free
				rm -rf /lesslinux/blobpart/avg-free
				exit 1
			fi
		fi
		[ -d /lesslinux/blobpart/avg-free -a "$retval" -lt 1 ] && rm /lesslinux/blobpart/avg-free.tgz 
	    fi
	fi
	if [ -f /opt/avg/av/etc/init.d/avgd.all ] ; then
	    DST_TREE=/opt/avg/av
	    export AVGINSTDIR=${DST_TREE}
	    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AVGINSTDIR/lib
	    export HOME=${HOME:-$AVGINSTDIR}
	    mkdir -p /var/lock/subsys 
	    bash /opt/avg/av/etc/init.d/avgd.all start
	fi
    ;;
    stop)
	printf "$bold===> Removing AVG, freeing memory $normal\n"
	DST_TREE=/opt/avg/av
	export AVGINSTDIR=${DST_TREE}
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$AVGINSTDIR/lib
	export HOME=${HOME:-$AVGINSTDIR}
	bash /opt/avg/av/etc/init.d/avgd.all stop
	unset LD_LIBRARY_PATH
	unset HOME
	sleep 2
	umount /root/.avg
	umount /opt/avg
    ;;
esac


