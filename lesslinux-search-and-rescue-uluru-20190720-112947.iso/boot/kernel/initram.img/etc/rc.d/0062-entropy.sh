#!/static/bin/ash

#lesslinux provides entropy

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Start entropy gathering daemon

case $1 in 
  start)
	printf "$bold===> Setting up entropy harvesting daemon $normal\n"
	[ -x /static/bin/haveged ] && /static/bin/haveged -w 4096
  ;;
esac    

printf "$normal"

# END		
