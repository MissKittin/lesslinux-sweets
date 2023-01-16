#!/static/bin/ash
		
#lesslinux provides sudo
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if [ "$laxsudo" -gt 0 ] ; then
	    cp /etc/sudoers.lax /etc/sudoers
	else
	    cp /etc/sudoers.strict /etc/sudoers
	fi
	chmod 0440 /etc/sudoers
	if [ "$allowsudosu" -gt 0 ] ; then
	    printf "$bold===> Adjusting sudo $normal\n"
	    echo '' >> /etc/sudoers
	    echo '# added by /etc/rc.d/0505-sudo.sh' >> /etc/sudoers
	    echo 'surfer  ALL = /bin/su' >> /etc/sudoers
	fi
    ;;
esac

		
