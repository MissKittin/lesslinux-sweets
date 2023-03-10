#!/static/bin/ash
		
#lesslinux provides openssl
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Preparing OpenSSL $normal\n"
	if [ -L /etc/ssl/certs ] ; then
		printf "$bold---> Skipping OpenSSL $normal\n"
	elif [ -d /etc/ssl/certs ] ; then
		mv /etc/ssl/certs /etc/ssl/certs.bak
		ln -sf /usr/share/ca-certificates /etc/ssl/certs
		printf "$bold---> Created symlink for OpenSSL certificates $normal\n"
	fi
    ;;
esac

		
