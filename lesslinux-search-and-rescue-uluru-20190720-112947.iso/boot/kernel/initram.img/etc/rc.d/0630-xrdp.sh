#!/static/bin/ash
		
#lesslinux provides xrdp
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

start_xrdp=0
xrdp_keys=/etc/xrdp/rsakeys.ini

for i in `cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline`
do
   case "$i" in
     xrdp=*)
	xrdp=`echo "$i" | awk -F '=' '{print $2}'`
	[ "$xrdp" -gt 0 ]  && start_xrdp=1
	[ "$xrdp" = true ] && start_xrdp=1
     ;;
   esac
done   

case $1 in 
    start)
	if [ "$start_xrdp" -gt 0 ] ; then
		printf "$bold===> Enable RDP access $normal\n"
		[ -f "$xrdp_keys" ] || xrdp-keygen xrdp "$xrdp_keys"
		/etc/xrdp/xrdp.sh start
	fi
    ;;
    stop)
	printf "$bold===> Stopping RDP access $normal\n"
	/etc/xrdp/xrdp.sh stop
    ;;
esac

		
