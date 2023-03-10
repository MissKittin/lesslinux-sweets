#!/bin/bash
		
#lesslinux provides openvas
#lesslinux parallel
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

OVASVERSION=9.0.3

# Edit, test...
# exit 0

case $1 in 
    start)
	if mountpoint -q /usr/var/lib/openvas ; then
	    printf "$bold===> Skipping OPENVAS, already mounted $normal\n"
	else
	    printf "$bold===> Preparing OPENVAS $normal\n"
	    for d in lib log cache ; do
		mkdir -p /usr/var/${d}/openvas
	    done
	    if mountpoint -q /lesslinux/blobpart ; then
		if [ -f /lesslinux/blobpart/openvas/.${OVASVERSION} ] ; then
			printf "$normal---> Found matching version $normal\n"
		else
			rm -rf /lesslinux/blobpart/openvas
		fi
		mkdir -p /lesslinux/blobpart/openvas
		mount --bind /lesslinux/blobpart/openvas /usr/var/lib/openvas
	    else
		mount -t tmpfs -o mode=0755,size=2048M tmpfs /usr/var/lib/openvas
	    fi
	    for d in CA private ; do
		mkdir -p /usr/var/lib/openvas/${d}
		mount -t tmpfs -o mode=0755,size=32M tmpfs /usr/var/lib/openvas/${d}
	    done
	    mkdir -p /usr/var/lib/openvas/openvasmd/gnupg
	    openvas-manage-certs -a
	fi
	mountpoint -q /lesslinux/blobpart && touch /lesslinux/blobpart/openvas/.${OVASVERSION}
	touch /var/log/lesslinux/bootlog/openvas.done
    ;;
    stop)
	printf "$bold===> Removing OPENVAS, freeing memory $normal\n"
	killall gsad
	killall openvassd
	killall openvasmd 
	killall -9 gsad
	killall -9 openvassd
	killall -9 openvasmd
	for d in CA private ; do
	    umount /usr/var/lib/openvas/${d}
	done
	umount /usr/var/lib/openvas
	umount /usr/var/log/openvas
    ;;
esac


