#!/static/bin/ash
		
#lesslinux provides lpd
#lesslinux license BSD

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if [ -n "$printers" ] ; then
		printf "$bold===> Starting LPD $normal\n"
		mkdir -p /var/spool/lpd
		for p in ` echo $printers | sed 's/|/ /g' ` ; do
			ln -sf /dev/usb/$p /var/spool/lpd/$p  
		done
		/static/bin/tcpsvd -E 0 515 /static/sbin/lpd /var/spool/lpd & 
	fi
    ;;
esac

# The end	
