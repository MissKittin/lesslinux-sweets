#!/bin/bash
		
#lesslinux provides qemu
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	groupadd -g 60042 kvm
	usermod -a -G kvm surfer
	chown -R root:kvm /dev/kvm 
	chmod 0660 /dev/kvm
    ;;
esac
		
