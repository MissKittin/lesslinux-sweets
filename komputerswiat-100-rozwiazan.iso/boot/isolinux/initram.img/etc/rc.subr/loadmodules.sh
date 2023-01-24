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
		# FIXME should not be hardcoded:
		if [ "$modname" = "loop" ] ; then
		    insmod /static/modules/$modname.ko max_loop=64 > /dev/null 2>&1
		else
		    # if the modprobe command exists plus the directory 
		    # /lib/modules/` uname -r ` is available we might use
		    # use the more sophisticated modprobe command!
		    # WARNING! Make sure we use the kernel's modprobe!
		    if [ -d /lib/modules/` uname -r `/kernel ] && which modprobe.static > /dev/null ; then
		        modprobe.static -q -b $modname 
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
