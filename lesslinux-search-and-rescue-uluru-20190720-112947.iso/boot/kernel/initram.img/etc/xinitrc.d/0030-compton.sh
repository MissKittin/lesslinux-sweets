#!/static/bin/ash
		
#lesslinux provides compton
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	compton --shadow-exclude '_GTK_FRAME_EXTENTS@:c' --fade-exclude '_GTK_FRAME_EXTENTS@:c' -cCGbf 
    ;;
esac

		
