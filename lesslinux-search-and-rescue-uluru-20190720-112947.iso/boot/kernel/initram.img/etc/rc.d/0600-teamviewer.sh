#!/bin/bash
		
#lesslinux provides teamviewer
#lesslinux parallel
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
# TVVERSION="v12.0.137452"
TVVERSION="14.3.4730"

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Preparing TeamViewer $normal\n"
	if mountpoint -q /opt/teamviewer ; then
		printf "$bold---> Seems to be mounted, skipping $normal\n"
		exit 0
	fi
	if [ -f /lesslinux/blob/teamviewer/.${TVVERSION} ] ; then
		printf "$bold---> Current version found $normal\n"
	elif [ -d /lesslinux/blob/teamviewer ] ; then
		rm -rf /lesslinux/blob/teamviewer
	fi
	if [ -d /lesslinux/blob/teamviewer ] ; then
		mount --bind  /lesslinux/blob/teamviewer /opt/teamviewer/teamviewer
		mount -o loop /opt/teamviewer/teamviewer/tv_bin.sqs /opt/teamviewer/teamviewer/tv_bin
	elif [ -f /lesslinux/blob/teamviewer_${TVVERSION}_i386.tar.xz ] ; then
		mount -t tmpfs -o mode=0755,size=256M tmpfs /opt/teamviewer
		tar -C /opt/teamviewer -xvf /lesslinux/blob/teamviewer_${TVVERSION}_i386.tar.xz
		chown -R root:root /opt/teamviewer
		( cd /opt/teamviewer/teamviewer ; mksquashfs tv_bin tv_bin.sqs )
		rm -rf /opt/teamviewer/teamviewer/tv_bin
		mkdir -p /opt/teamviewer/teamviewer/tv_bin
		if mountpoint /lesslinux/blobpart && mkdir /lesslinux/blobpart/teamviewer ; then
			tar -C /opt/teamviewer -cvf - teamviewer | tar -C /lesslinux/blobpart -xf - 
			sync
			umount /opt/teamviewer
			ln -sf /lesslinux/blobpart/teamviewer /lesslinux/blob/
			mount --bind  /lesslinux/blob/teamviewer /opt/teamviewer/teamviewer
		fi
		mount -o loop /opt/teamviewer/teamviewer/tv_bin.sqs /opt/teamviewer/teamviewer/tv_bin
		touch /lesslinux/blob/teamviewer/.${TVVERSION}
	fi
	touch /var/log/lesslinux/bootlog/teamviewer.done
	if [ -x /opt/teamviewer/teamviewer/tv_bin/teamviewerd ] ; then
		/opt/teamviewer/teamviewer/tv_bin/teamviewerd -d 
	fi
    ;;
    stop)
	printf "$bold===> Removing TeamViewer $normal\n"
	if [ -f /opt/teamviewer/teamviewer/teamviewer ] ; then
		# killall TeamViewer.exe
		killall -15 teamviewerd
		sleep 5
		# killall -9 TeamViewer.exe
		killall -9 teamviewerd 
	fi
	umount /opt/teamviewer/teamviewer/logfiles
	umount /opt/teamviewer/teamviewer/profile
	umount /opt/teamviewer/teamviewer/config
	umount /opt/teamviewer/teamviewer/tv_bin
	umount /opt/teamviewer/teamviewer
	umount /opt/teamviewer
	tvloop=` losetup -a | grep teamviewer | awk -F ':' '{print $1}' ` 
	[ -n "$tvloop" ] && losetup -d "$tvloop" 
    ;;
esac
		
