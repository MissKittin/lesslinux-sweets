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
		# FIXME should not ne hardcoded:
		if [ "$modname" = "loop" ] ; then
		    insmod /static/modules/$modname.ko max_loop=64 > /dev/null 2>&1
		else
		    insmod /static/modules/$modname.ko > /dev/null 2>&1
		fi
	    fi
        ;;
    esac
done
mdev -s
		
#		
