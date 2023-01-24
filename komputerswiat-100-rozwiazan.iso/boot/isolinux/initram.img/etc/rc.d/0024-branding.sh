#!/static/bin/ash

#lesslinux provides branding

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# Write branding, essentially create some softlinks according to the selected language

case $1 in 
    start)
	printf "$bold===> Writing branding $normal \n"
	cat /etc/lesslinux/branding/filelist.txt | sort | uniq | while read fname ; do
	    if [ -f "$fname"."$lang" ] ; then
	        ln -sf "$fname"."$lang" "$fname"
	    elif [ -f "$fname".en ] ; then
	        ln -sf "$fname".en "$fname"
	    fi
	done
    ;;
esac
#		
