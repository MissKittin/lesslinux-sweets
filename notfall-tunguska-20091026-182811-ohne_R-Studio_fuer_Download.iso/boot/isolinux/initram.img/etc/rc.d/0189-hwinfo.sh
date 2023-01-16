#!/static/bin/ash
		
#lesslinux provides hwinfo
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Preparing hardware information $normal\n"
	now=` date +%Y%m%d-%H%M `
	mkdir /tmp/hwinfo
        lshw-static -xml -sanitize > /tmp/hwinfo/lshw.xml
	lshw-static -html -sanitize > /tmp/hwinfo/lshw.html
	lshw-static -short -sanitize > /tmp/hwinfo/lshw.txt
	Xvesa -listmodes 2> /tmp/hwinfo/vesamodes.txt
	cat /proc/cpuinfo > /tmp/hwinfo/cpuinfo.txt
	cat /proc/meminfo > /tmp/hwinfo/meminfo.txt
	lsmod > /tmp/hwinfo/lsmod.txt
	lspci -nn > /tmp/hwinfo/lspci.txt
	lsusb -vv > /tmp/hwinfo/lsusb.txt
	( cd /tmp && tar cjf hwinfo_${now}.tbz hwinfo )
    ;;
esac

# The end	
