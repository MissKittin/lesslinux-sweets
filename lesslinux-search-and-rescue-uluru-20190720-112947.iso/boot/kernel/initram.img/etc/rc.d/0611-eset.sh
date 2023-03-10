#!/bin/bash
		
#lesslinux provides eset
#lesslinux parallel
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

[ -x /var/run/lesslinux/bootdevice.udev ] && . /var/run/lesslinux/bootdevice.udev

case $1 in 
    start)
	if mountpoint -q /lesslinux/eset/sys ; then
	    printf "$bold===> Skipping ESET, already mounted $normal\n"
	else
	    printf "$bold===> Preparing ESET $normal\n"
	    esetiso=""
	    esetsys=""
	    mkdir -m 0755 -p /lesslinux/eset/iso
	    if mountpoint -q /lesslinux/blobpart ; then
		[ -f /lesslinux/blobpart/eset_sysrescue_live_enu.iso ] && esetiso="/lesslinux/blobpart/eset_sysrescue_live_enu.iso"
		[ -f /lesslinux/blobpart/eset/eset_sysrescue_live_enu.iso ] && esetiso="/lesslinux/blobpart/eset/eset_sysrescue_live_enu.iso"
		[ -f /lesslinux/blobpart/eset/eset.iso ] && esetiso="/lesslinux/blobpart/eset/eset.iso"
		[ -f /lesslinux/blobpart/eset/eset.sqs ] && esetsys="/lesslinux/blobpart/eset/eset.sqs"
	    fi
	    if [ -z "$esetiso" -a -z "$esetsys" ] ; then
		[ -f /lesslinux/blob/eset/eset_sysrescue_live_enu.iso ] && esetiso="/lesslinux/blob/eset/eset_sysrescue_live_enu.iso"
		[ -f /lesslinux/blob/eset/eset.iso ] && esetiso="/lesslinux/blob/eset/eset.iso"
		[ -f /lesslinux/blob/eset/eset.sqs ] && esetsys="/lesslinux/blob/eset/eset.sqs"
	    fi
	    # Try to find any ISO image on DVD that contains a file casper/04_eset.squashfs
	    if [ -z "$esetiso" -a -z "$esetsys" ] && mountpoint -q /lesslinux/cdrom ; then
	        for isoname in ` find /lesslinux/cdrom -maxdepth 3 -name '*.iso' ` ; do
		    mount -t iso9660 -o loop "$isoname" /lesslinux/eset/iso
		    [ -f /lesslinux/eset/iso/casper/04_eset.squashfs ] && esetiso="$isoname"
		    umount /lesslinux/eset/iso
		done
	    fi
	    
	    # ESET not found? Exit!
	    if [ -z "$esetiso" -a -z "$esetsys" ] ; then
		touch /var/log/lesslinux/bootlog/eset.done
		exit 0
	    fi
	    # Copy the squashfs if blobpart available but sqs not yet there!
	    if [ -n "$esetsys" -a '!' -d /lesslinux/blobpart/eset ] ; then
		mkdir -p /lesslinux/blobpart/eset 
		cp -v "$esetsys" /lesslinux/blobpart/eset 
	    fi
	    
	    mkdir -m 0755 -p /lesslinux/eset/sys
	    mkdir -m 0755 -p /lesslinux/blob/eset
	    mkdir -m 0755 -p /mnt/eset-live-rw
	    mkdir -m 0755 -p /var/log/esets
	    mkdir -m 0755 -p /etc/opt/eset
	    
	    
	    # Mount the ISO if no SQS is available
	    if [ -z "$esetsys" ] ; then
		mount -o loop "$esetiso" /lesslinux/eset/iso
		if mountpoint -q /lesslinux/blobpart ; then
		    mkdir -p /lesslinux/blobpart/eset
		    cp /lesslinux/eset/iso/casper/04_eset.squashfs /lesslinux/blobpart/eset/eset.sqs && \
		    umount /lesslinux/eset/iso && \
		    rm "$esetiso"
		    esetsys="/lesslinux/blobpart/eset/eset.sqs"
		else
		    cp -v /lesslinux/eset/iso/casper/04_eset.squashfs /lesslinux/blob/eset/eset.sqs && \
		    umount /lesslinux/eset/iso 
		    esetsys="/lesslinux/blob/eset/eset.sqs"
		fi
	    fi
	    
	    # Now mount ESETs SquashFS
	    mount -o loop "$esetsys" /lesslinux/eset/sys
	    # Bind mount the system directory
	    mount --bind /lesslinux/eset/sys/opt/eset /opt/eset
	    mount --bind /lesslinux/eset/sys/var/opt/eset /var/opt/eset
	    # Create log and config dir on blobpart if available
	    if mountpoint -q /lesslinux/blobpart ; then
		ln -s /lesslinux/blobpart/eset/lib /mnt/eset-live-rw/lib
		mkdir -p /lesslinux/blobpart/eset/log 
		if [ -d /lesslinux/blobpart/eset/lib ] ; then
		    mount --bind /lesslinux/blobpart/eset/etc /etc/opt/eset
		else
		    rsync -avHP /lesslinux/eset/sys/mnt/eset-live-rw/lib/ /lesslinux/blobpart/eset/lib/
		    rsync -avHP /lesslinux/eset/sys/etc/opt/eset/ /lesslinux/blobpart/eset/etc
		    mount --bind /lesslinux/blobpart/eset/etc /etc/opt/eset
		fi
		mount --bind /lesslinux/blobpart/eset/log /var/log/esets 
	    else
		mkdir -p /mnt/eset-live-rw/lib
		mount -t tmpfs -o mode=0755,size=512M tmpfs /mnt/eset-live-rw/lib/
		rsync -avHP /lesslinux/eset/sys/mnt/eset-live-rw/lib/ /mnt/eset-live-rw/lib/
		rsync -avHP /lesslinux/eset/sys/etc/opt/eset/ /etc/opt/eset/
		# Search on partition containing the loop device, unpack as needed
		if [ "$ID_FS_TYPE" = ntfs ] ; then
			mkdir /tmp/eset
			mount -o ro -t ntfs-3g /dev/disk/by-uuid/${ID_FS_UUID} /tmp/eset
			tar -C /etc/opt/eset -xf /tmp/eset/cobirescue/esetetc.tgz
			tar -C /mnt/eset-live-rw -xf /tmp/eset/cobirescue/esetlib.tgz
			umount /tmp/eset
			rmdir /tmp/eset 
		fi
	    fi
	    # Write username if available
	    esetrand=""
	    [ -f /lesslinux/blob/eset/esetrand ] && esetrand="/lesslinux/blob/eset/esetrand"
	    [ -f /lesslinux/blobpart/eset/esetrand ] && esetrand="/lesslinux/blobpart/eset/esetrand"
	    if grep av_update_username /etc/opt/eset/esets/esets.cfg  ; then
		echo "Username is already written..." 
	    elif [ -n "$esetrand" ] ; then
	        install -m 0755 "$esetrand" /static/sbin
		/static/sbin/esetrand >> /etc/opt/eset/esets/esets.cfg
	    fi
	    # Now start the daemon
	    /opt/eset/esets/sbin/esets_daemon
	fi
	touch /var/log/lesslinux/bootlog/eset.done
    ;;
    stop)
	printf "$bold===> Unmounting ESET $normal\n"
	if cat /proc/mounts | grep -q /lesslinux/eset/sys ; then
	    killall -9 esets_scan 
	    killall esets_daemon
	    sleep 3
	    killall -9 esets_daemon
	    if [ "$ID_FS_TYPE" = ntfs ] ; then
		# When loop still mounted, the device is probably mounted ro, so a simple unmount should suffice
		mkdir /tmp/eset
		umount -f /dev/disk/by-uuid/${ID_FS_UUID}
		ntfs-3g.probe --readwrite /dev/disk/by-uuid/${ID_FS_UUID} && mount -o rw -t ntfs-3g /dev/disk/by-uuid/${ID_FS_UUID} /tmp/eset
		if mountpoint -q /tmp/eset ; then
			mkdir -p /tmp/eset/cobirescue
			tar -C /etc/opt/eset -czf /tmp/eset/cobirescue/esetetc.tgz .
			tar -C /mnt/eset-live-rw -czf /tmp/eset/cobirescue/esetlib.tgz .
			sync 
			umount /tmp/eset || umount -f /tmp/eset 
			rmdir /tmp/eset
		fi
	    fi
	    mountpoint -q /mnt/eset-live-rw/lib/ && umount /mnt/eset-live-rw/lib/
	    mountpoint -q /etc/opt/eset && umount /etc/opt/eset
	    mountpoint -q /var/log/esets && umount /var/log/esets
	    umount /var/opt/eset
	    umount /opt/eset
	    umount /lesslinux/eset/sys
	    mountpoint -q /lesslinux/eset/iso && umount /lesslinux/eset/iso
	fi
	
    ;;
esac

		
