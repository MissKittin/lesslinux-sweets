#!/static/bin/ash
		
#lesslinux provides updater
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors 

case $1 in 
    start)
	check_lax_sudo || exit 1 
	uid=` id -u ` 
	[ "$uid" -gt 0 ] || exit 1 
	matchbox-window-manager -force-dialogs Update &
	sudo /etc/lesslinux/updater/updater.sh --quiet 
	killall -9 matchbox-window-manager
	if [ -f /tmp/lesslinux/updater.tbz.asc ] ; then
		echo '===> Previous check for update successful'
	else
		( sleep 600 ; sudo /etc/lesslinux/updater/updater.sh --quiet ) & 
	fi
    ;;
esac

		
