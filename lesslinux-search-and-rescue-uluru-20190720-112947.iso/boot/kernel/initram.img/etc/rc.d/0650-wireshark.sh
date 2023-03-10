#!/static/bin/ash
		
#lesslinux provides wireshark
#lesslinux parallel
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
 
case $1 in 
    start)
	printf "$bold===> Preparing Wireshark $normal\n"
	install -m 4755 /usr/bin/dumpcap /static/bin 
	mountpoint -q /usr/bin/dumpcap || mount --bind /static/bin/dumpcap /usr/bin/dumpcap
	touch /var/log/lesslinux/bootlog/wireshark.done
    ;;
    stop)
	printf "$bold===> Removing Wireshark $normal\n"
	umount /usr/bin/dumpcap
    ;;
esac

		
