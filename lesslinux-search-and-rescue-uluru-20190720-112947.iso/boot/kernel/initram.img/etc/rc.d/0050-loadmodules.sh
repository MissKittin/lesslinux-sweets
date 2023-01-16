#!/static/bin/ash

#lesslinux provides loadmodules

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Load some additional modules that might not be loaded by the other scripts

# Find modprobe command
MODPROBE=modprobe
# Statically linked modprobe/kmod in initramfs
if [ -x /static/kmod/bin/kmod ] ; then
	ln -sf /static/kmod/bin/kmod /static/kmod/bin/modprobe
	ln -sf /static/kmod/bin/kmod /static/kmod/bin/insmod
	MODPROBE=/static/kmod/bin/modprobe
	PATH=/static/kmod/bin:$PATH
	export PATH
fi
# Modprobe provided by kmod in complete system
[ -x /bin/kmod ] && MODPROBE=/sbin/modprobe
# Modprobe provided by kmod in complete system - alternative path
[ -x /usr/bin/kmod ] && MODPROBE=/usr/sbin/modprobe

case $1 in
    start)
	# write blacklist first
	for i in ` echo "$skipmodules" | sed 's/|/ /g' ` ; do
	    echo "blacklist $i" >> /etc/modprobe.d/blacklist.conf
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
		    if [ -d /lib/modules/` uname -r `/kernel ] ; then
		        $MODPROBE -q -b $modname 
		    else
			insmod -q /static/modules/$modname.ko
		    fi
		fi
	    done
	    mdev -s
	fi
	kversion=` uname -r `
	alreadyloaded=""
	# Now use our faked lspci and faked lsusb to load additional modules
	if [ -d /lib/modules/${kversion}/kernel ] ; then
	    
	    # Hide wireless modules, those should probably loaded after udev is started
	    # to work around flaws with crda
	    # mount -t tmpfs tmpfs -o mode=0755 /lib/modules/${kversion}/kernel/drivers/net/wireless/
	    # Hide DRM modules, since they request firmware, they should be loaded after 
	    # udev is started
	    # mount -t tmpfs tmpfs -o mode=0755 /lib/modules/${kversion}/kernel/drivers/gpu/drm
	    # Hide sound modules, since they request firmware, they should be loaded after 
	    # udev is started
	    # mount -t tmpfs tmpfs -o mode=0755 /lib/modules/${kversion}/kernel/sound
	    
	    defmods=` echo $defermods | sed 's%|% %g' `
	    for dir in $defmods ; do
		mount -t tmpfs -o mode=0755 tmpfs /lib/modules/${kversion}/kernel/${dir}
	    done
	    
	    printf "$bold===> Loading PCI drivers $normal\n"
	    for i in /sys/bus/pci/devices/* ; do 
		prod=` cat $i/device | sed 's/0x//' `
		vend=` cat $i/vendor | sed 's/0x//' `
		if [ -f /lib/modules/${kversion}/modules.pcimap ] ; then
		    for modname in \
		        ` cat /lib/modules/${kversion}/modules.pcimap | awk '{print $1, $2, $3}' | \
			    grep -Ei ' 0x0000'${vend}' 0x0000'${prod}'$| 0x0000'${vend}' 0xffffffff$| 0xffffffff 0x0000'${prod}'$' | awk '{print $1}' ` ; do
			if echo "$alreadyloaded" | grep -qv "$modname " ; then
			    $MODPROBE -q -b $modname
			    alreadyloaded="$alreadyloaded $modname "
		        fi
		    done
		else
		    for modname in \
			` grep -Ei 'alias pci:v0000'${vend}d0000${prod}'sv|alias pci:v\*d0000'${prod}'sv|alias pci:v0000'${vend}'d\*sv' /lib/modules/${kversion}/modules.alias | awk '{print $3}' | uniq ` ; do
			if echo "$alreadyloaded" | grep -qv "$modname " ; then
			    $MODPROBE -q -b $modname
			    alreadyloaded="$alreadyloaded $modname "
		        fi
		    done
		fi
	    done
	    if [ -f /lib/modules/${kversion}/modules.pcimap ] ; then
		for modname in \
		    ` cat /lib/modules/${kversion}/modules.pcimap | awk '{print $1, $2, $3}' | \
			grep -i ' 0xffffffff 0xffffffff$' | awk '{print $1}' ` ; do
		    if echo "$alreadyloaded" | grep -qv "$modname " ; then
			$MODPROBE -q -b $modname
			alreadyloaded="$alreadyloaded $modname "
		    fi
		done
	    else
		for modname in \
		    ` cat /lib/modules/${kversion}/modules.alias |  grep -Ei 'alias pci:v\*d\*sv' | awk '{print $3}' | uniq ` ; do
			if echo "$alreadyloaded" | grep -qv "$modname " ; then
			    $MODPROBE -q -b $modname
			    alreadyloaded="$alreadyloaded $modname "
			fi
		    done
	    fi
	    printf "$bold===> Loading USB drivers $normal\n"
	    for i in /sys/bus/usb/devices/* ; do 
		if [ -f $i/idVendor ] ; then
		    prod=` cat $i/idProduct `
		    vend=` cat $i/idVendor `
		    if [ -f /lib/modules/${kversion}/modules.usbmap ] ; then
			for modname in \
			    ` cat /lib/modules/${kversion}/modules.usbmap | awk '{print $1, $3, $4}' | \
			        grep -Ei ' 0x'${vend}' 0x'${prod}'$| 0x'${vend}' 0xffff$| 0xffff 0x'${prod}'$' | awk '{print $1}' ` ; do 
			    if echo "$alreadyloaded" | grep -qv "$modname " ; then
				$MODPROBE -q -b $modname
				alreadyloaded="$alreadyloaded $modname "
		            fi
			done
		    else	
			for modname in \
			   ` grep -Ei 'alias usb:v'${vend}p${prod}'d|alias usb:v\*p'${prod}'d|alias usb:v'${vend}'p\*d' /lib/modules/${kversion}/modules.alias | awk '{print $3}' | uniq ` ; do
			    if echo "$alreadyloaded" | grep -qv "$modname " ; then
				$MODPROBE -q -b $modname
				alreadyloaded="$alreadyloaded $modname "
		            fi
			done
		    fi
		fi
	    done 
	    if [ -f /lib/modules/${kversion}/modules.usbmap ] ; then
		for modname in \
		    ` cat /lib/modules/${kversion}/modules.usbmap | awk '{print $1, $3, $4}' | \
		    grep -i ' 0xffff 0xffff$' | awk '{print $1}' ` ; do 
		    if echo "$alreadyloaded" | grep -qv "$modname " ; then
			$MODPROBE -q -b $modname
			alreadyloaded="$alreadyloaded $modname "
		    fi
		done
	    else
		for modname in \
		    ` grep -Ei 'alias usb:v\*p\*d' /lib/modules/${kversion}/modules.alias | awk '{print $3}' | uniq ` ; do
		    if echo "$alreadyloaded" | grep -qv "$modname " ; then
			$MODPROBE -q -b $modname
			alreadyloaded="$alreadyloaded $modname "
		    fi
		done   
	    fi
	    mountpoint -q /proc/bus/usb || mount -t usbfs usbfs /proc/bus/usb
	    if cat /sys/hypervisor/properties/capabilities | grep -q xen ; then
		printf "$bold===> Loading Xen specific drivers $normal \n"
		$MODPROBE -q -b xen-blkfront
		$MODPROBE -q -b xen-netfront
	    fi
	    mdev -s
	    for dir in $defmods ; do
		umount /lib/modules/${kversion}/kernel/${dir}
	    done
	fi
	if [ -p /splash.fifo ] ; then
		echo "exit" > /splash.fifo
		# Re-Write config
		fbwidth=` fbset | grep '^mode' | awk -F '["x-]' '{print $2}' `
		fbheight=` fbset | grep '^mode' | awk -F '["x-]' '{print $3}' `
		/etc/rc.subr/write_fbsplash_config $fbwidth $fbheight 
		chvt 8
		# Remove old fifo
		rm /splash.fifo
		# Create new (empty fifo)
		mkfifo /splash.fifo
		fbsplash -i /etc/lesslinux/fbsplash.cfg -s /etc/lesslinux/branding/fbsplash/splash.ppm -f /splash.fifo &
	fi
    ;;
esac

#		
