#!/static/bin/ash

PATH=/static/bin:/static/sbin:/bin:/sbin

. /etc/rc.conf
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Replace the hash for the root password

# cleanpwhash=`echo $rootpwhash | tr '$' '\$' | sed '/\//s//\\\\\//' `
# cat shadow.templ | sed "/%PWHASH%/s//${cleanpwhash}/g"

case $1 in 
    start)
    if [ "$nologin" -gt 0 ] ; then
        printf "$bold===> Skipping MD5 hash for root password $normal\n"
    else
        printf "$bold===> Replacing MD5 hash for root password                        "
        cleanpwhash=`echo $rootpwhash | tr '$' '\$' | sed '/\//s//\\\\\//' `
        if cat /etc/rc.templates/shadow | sed "/%PWHASH%/s//$cleanpwhash/g" > /etc/shadow
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
