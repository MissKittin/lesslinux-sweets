#!/static/bin/ash

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

cat $1 | awk '{print $1}' | while read modname
do
    case $modname in
        '#'*|'')
	    true
	;;
	*)
            if echo "$skipmodules" | grep '|'$modname'|' > /dev/null 2>&1 ; then
		printf "$bold---> Skipping blacklisted module $modname \n"
            else
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
	    
		# FIXME should not be hardcoded:
		if [ "$modname" = "loop" ] ; then
		    insmod /static/modules/$modname.ko max_loop=64 > /dev/null 2>&1
		else
		    # if the modprobe command exists plus the directory 
		    # /lib/modules/` uname -r ` is available we might use
		    # use the more sophisticated modprobe command!
		    # WARNING! Make sure we use the kernel's modprobe!
		    if [ -d /lib/modules/` uname -r `/kernel ] ; then
		        $MODPROBE -q -b $modname 
		    else
			insmod -q /static/modules/$modname.ko
		    fi
		fi
	    fi
        ;;
    esac
done
mdev -s
		
#		
