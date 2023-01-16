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
		    insmod /static/modules/$i.ko > /dev/null 2>&1
		fi
	    done
	    mdev -s
	fi
    ;;
esac

#		
