#!/static/bin/ash
	
#lesslinux provides hald
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "${bold}===> Starting HALD ${normal}\n"
	[ "$security" = "smack" ] && \
		echo netmgr > /proc/self/attr/current
	mkdir -p /etc/hal/fdi/preprobe
	mkdir -p /etc/hal/fdi/information
	mkdir -p /etc/hal/fdi/policy
	mkdir -p /usr/var/cache/hald
	/usr/libexec/hald-generate-fdi-cache
	/usr/sbin/hald --daemon=yes --use-syslog &
    ;;
    stop)
	true
        # echo "FIXME: properly stop hald"
    ;;
esac

			
