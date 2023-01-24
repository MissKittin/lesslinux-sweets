#!/static/bin/ash

#lesslinux provides lonet

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.subr/colors

# Start Loopback Networking (and never stop it!)

case $1 in 
    start)
	printf "$bold===> Setting up loopback networking $normal \n"
	ifconfig lo 127.0.0.1 
    ;;
esac
#		
