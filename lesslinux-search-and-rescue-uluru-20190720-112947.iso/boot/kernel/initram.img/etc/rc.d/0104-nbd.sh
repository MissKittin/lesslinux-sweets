#!/static/bin/ash
		
#lesslinux provides nbd
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin:
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

nbd=''
nbdhost=''
nbdport=''

for i in ` cat /proc/cmdline /etc/lesslinux/cmdline /lesslinux/boot/cmdline ` ; do
   case "$i" in
     nbd=*)
	nbd=`echo "$i" | awk -F '=' '{print $2}'`
	nbdhost=`echo "$nbd" | awk -F ':' '{print $1}'`
	nbdport=`echo "$nbd" | awk -F ':' '{print $2}'`
     ;;
   esac
done

case $1 in 
    start)
	if [ -n "$nbd" ] ; then
		printf "$bold===> Connecting network block device$normal\n"
		nbd-client "$nbdhost" "$nbdport" /dev/nbd0
	fi
    ;;
esac


