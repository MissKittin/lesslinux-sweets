#!/static/bin/ash
		
#lesslinux provides cdperm
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Relaxing permissions on optical drives $normal\n"
        for i in /dev/sr[0-9] ; do
	    basedev=` basename $i `
	    cat /proc/mounts | awk '{print $1}' | grep "$i" > /dev/null && sed -i "s/srX/$basedev/g" /etc/mdev.conf
	done
	sed -i "s/sr\[0-9\] 0:60008 0600/sr[0-9] 0:60008 0660/g" /etc/mdev.conf
	mdev -s
    ;;
esac    

		
