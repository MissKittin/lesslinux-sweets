#!/bin/bash
		
#lesslinux provides john
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

VERSION=1.8.0-jumbo-1

case $1 in 
    start)
	printf "$bold===> Making john writable $normal\n"
	if mountpoint -q /lesslinux/blobpart ; then
		if [ -d /lesslinux/blobpart/john-${VERSION} ] ; then
			mount --bind /lesslinux/blobpart/john-${VERSION} /opt/john-${VERSION}
		else
			tar -C /opt -cvf - john-${VERSION} | tar -C /lesslinux/blobpart -xf -
			mount --bind /lesslinux/blobpart/john-${VERSION} /opt/john-${VERSION}
		fi
	else
		tar -C /opt/john-${VERSION} -cvf /tmp/john.tar . 
		mount -t tmpfs -o mode=0755 tmpfs /opt/john-${VERSION}
		tar -C /opt/john-${VERSION} -xvf /tmp/john.tar 
		rm /tmp/john.tar 
	fi
    ;;
    stop)
	printf "$bold===> Removing john, freeing memory $normal\n"
	umount /opt/john-${VERSION}
    ;;
esac


