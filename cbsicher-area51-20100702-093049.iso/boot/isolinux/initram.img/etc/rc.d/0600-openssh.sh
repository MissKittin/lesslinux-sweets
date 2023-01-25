#!/static/bin/ash
		
#lesslinux provides ssh
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in 
    start)
	printf "$bold===> Starting OpenSSH daemon $normal\n"
	mkdir /var/empty
	if [ -f /etc/openssh/ssh_host_dsa_key ] ; then
	    printf "$bold---> Skipping DSA key $normal\n"
	else
	    ssh-keygen -N '' -t dsa -f /etc/openssh/ssh_host_dsa_key
	fi
	if [ -f /etc/openssh/ssh_host_rsa_key ] ; then
	    printf "$bold---> Skipping RSA key $normal\n"
	else
	    ssh-keygen -N '' -t rsa -f /etc/openssh/ssh_host_rsa_key
	fi
	if check_lax_sudo ; then
		echo '' >> /etc/sudoers
		echo '# added by /etc/rc.d/0600-openssh.sh' >> /etc/sudoers
		echo '# surfer might start/stop the SSH daemon' >> /etc/sudoers
		echo 'surfer  ALL = NOPASSWD: /etc/rc.d/0600-openssh.sh' >> /etc/sudoers
	fi
	/usr/sbin/sshd
    ;;
    stop)
	printf "$bold===> Stopping OpenSSH daemon $normal\n"
	sshdpid=` pidof sshd `
	kill $sshdpid
	kill -9 $sshdpid
    ;;
esac

		
