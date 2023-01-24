#!/static/bin/ash

#lesslinux provides loadmodules

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Load some additional modules that might not be loaded by the other scripts

case $1 in
    start)
	# write blacklist first
	for i in ` echo "$skipmodules" | sed 's/|/ /g' ` ; do
	    echo "blacklist $i" >> /etc/modprobe.d/blacklist
	done
        if [ -z "$loadmodules" ] ; then
	    printf "$bold===> No additional modules to load $normal\n"
	else
	    printf "$bold===> Load some additional modules $normal\n"
	    for i in ` echo "$loadmodules" | sed 's/|/ /g' ` 
	    do
		# FIXME should not be hardcoded:
		if [ "$i" = "loop" ] ; then
		    insmod /static/modules/$i.ko max_loop=64 > /dev/null 2>&1
		else
		    if [ -d /lib/modules/` uname -r `/kernel ] && which modprobe.static > /dev/null ; then
		        modprobe.static -q -b $modname 
		    else
			insmod -q /static/modules/$modname.ko
		    fi
		fi
	    done
	    mdev -s
	fi
	# Now use our faked lspci and faked lsusb to load additional modules
	if [ -d /lib/modules/` uname -r `/kernel ] && which modprobe.static > /dev/null ; then
	    printf "$bold===> Loading PCI drivers $normal\n"
	    for i in /sys/bus/pci/devices/* ; do 
		prod=` cat $i/device | sed 's/0x//' `
		vend=` cat $i/vendor | sed 's/0x//' `
		if [ -f  /lib/modules/` uname -r `/modules.pcidir/${vend}_${prod} ] ; then
		    kversion=` uname -r `
		    for modname in ` cat /lib/modules/${kversion}/modules.pcidir/${vend}_${prod} ` ; do
			modprobe.static -q -b $modname
		    done
		fi
	    done
	    printf "$bold===> Loading USB drivers $normal\n"
	    for i in /sys/bus/usb/devices/* ; do 
		if [ -f $i/idVendor ] ; then
		    prod=` cat $i/idProduct `
		    vend=` cat $i/idVendor `
		    if [ -f  /lib/modules/` uname -r `/modules.usbdir/${vend}_${prod} ] ; then
			kversion=` uname -r `
			for modname in ` cat /lib/modules/${kversion}/modules.usbdir/${vend}_${prod} ` ; do
			    modprobe.static -q -b $modname
			done
		    fi
		fi
	    done
	fi
    ;;
esac

#		
