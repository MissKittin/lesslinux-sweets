#!/static/bin/ash
		
#lesslinux provides filezilla
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	if [ "$security" = "smack" ] ; then
		printf "$bold===> Adjusting sudo permissions for FileZilla $normal\n"
		echo '' >> /etc/sudoers
		echo '# added by /etc/rc.d/0610-filezilla.sh' >> /etc/sudoers
		echo 'surfer   ALL = NOPASSWD: /opt/bin/filezilla_smack' >> /etc/sudoers
	fi
    ;;
esac

		
