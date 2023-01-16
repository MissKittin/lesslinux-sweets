#!/static/bin/ash
		
#lesslinux provides hostname
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
        currhost=` hostname `
	if [ -z "$currhost" -o '?' = "$currhost" -o '(none)' = "$currhost" ] ; then
	    printf "$bold===> Setting hostname                                            "
	    if hostname "$hostname" > /dev/null 2>&1 ; then
	        printf "$success"
            else       
                printf "$failed"
            fi
	fi
	currhost="$hostname"
	if [ -f /etc/hosts ] ; then
	    if grep "$currhost" /etc/hosts > /dev/null 2>&1 ; then
		printf "$bold---> Hostname already in /etc/hosts $normal\n"
	    else
		echo "127.0.0.1 $currhost" >> /etc/hosts
	    fi
	else
	    echo "127.0.0.1 localhost $currhost" > /etc/hosts
	fi
    ;;
esac

# END		
