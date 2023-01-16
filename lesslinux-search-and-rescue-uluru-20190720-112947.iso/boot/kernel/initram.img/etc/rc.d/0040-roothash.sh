#!/static/bin/ash

#lesslinux provides roothash

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/rc.defaults.override ] && . /etc/rc.defaults.override

# Replace the hash for the root password

case $1 in
    start)
    if [ "$nologin" -gt 0 ] ; then
        printf "$bold===> Skipping MD5 hash for root password $normal\n"
    else      
        printf "$bold===> Replacing MD5 hash for root password 	                 "
	if [ -n "$roothash" ] ; then
		rootpwhash=` echo "$roothash" | base64 -d | sed 's/ //g' ` 
	elif [ -f /etc/lesslinux/root.hash ] ; then
		rootpwhash=` cat /etc/lesslinux/root.hash `
		chmod 0600 /etc/lesslinux/root.hash
		chown root:root /etc/lesslinux/root.hash
	else
		rootpwhash='!'
	fi
	if [ -f /etc/lesslinux/surfer.hash ] ; then
		userpwhash=` cat /etc/lesslinux/surfer.hash `
		chmod 0600 /etc/lesslinux/surfer.hash
		chown root:root /etc/lesslinux/surfer.hash
	else
		userpwhash='!'
	fi
        clean_rootpwhash=`echo $rootpwhash | tr '$' '\$' | sed '/\//s//\\\\\//g' `
	clean_userpwhash=`echo $userpwhash | tr '$' '\$' | sed '/\//s//\\\\\//g' `
        if cat /etc/rc.templates/shadow | sed "/%ROOTHASH%/s//$clean_rootpwhash/g" | sed "/%USERHASH%/s//$clean_userpwhash/g" > /etc/shadow
            then
            chown root:root /etc/shadow > /dev/null 2>&1
            chmod 0600 /etc/shadow > /dev/null 2>&1
            printf "$success"
        else
            printf "$failed"
            printf "$bold---> Shell login as root might not be possible...$normal\n"
        fi
    fi
  ;;
esac
#		
