#!/static/bin/ash
		
#lesslinux provides xsetroot
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	mkdir -p ${HOME}/.lesslinux
	xsetroot -solid gray && touch ${HOME}/.lesslinux/xsetroot_successful
    ;;
esac

		
