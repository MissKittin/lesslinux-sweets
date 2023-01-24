#!/static/bin/ash
		
#lesslinux provides smack
#lesslinux license BSD
		
PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors		
		
case $1 in 
    start)	
        if [ "$security" = "smack" ] ; then
	    printf "$bold===> Enable Simple Mandatory Access Control Kernel$normal\n"
	    # bend some softlinks for the patched tools
	    for i in id ls stat find adduser login su crontab ps ; do
	        ln -sf /static/bin/busybox_smack /static/bin/$i
	    done
	    for i in sulogin crond newsmack smackcipso smackenabled smackload ; do
	        ln -sf /static/bin/busybox_smack /static/sbin/$i
	    done
	    # Set some security labels (we need /usr/bin/attr or /static/bin/attr here!)
	    printf "$bold===> xattr on tmpfs root filesystem might be set here\n"
	    # Mount smackfs
	    mkdir /smack > /dev/null 2>&1
	    mount -t smackfs smackfs /smack
	    # load the appropriate rules and users
	    if [ -f /etc/smack/accesses ] ; then
		smackload < /etc/smack/accesses
	    fi
            if [ -f /etc/smack/cipso ] ; then
                smackcipso < /etc/smack/cipso
            fi
            if [ -f /etc/smack/ambient ] ; then
                cat /etc/smack/ambient > /smack/ambient
            fi
            if [ -f /etc/smack/nltype ] ; then
                cat /etc/smack/nltype > /smack/nltype
            fi
	    if [ -f /etc/smack/netlabel ] ; then
                echo '127.0.0.1/32 @' > /smack/netlabel
		if echo "$skipservices" | grep -q '|smacknet|' ; then
		    # FIXME: Should not be hardcoded
		    # echo '172.16.0.0/16 outgoing' > /smack/netlabel
		    # echo '192.168.0.0/16 outgoing' > /smack/netlabel
		    # echo '169.254.0.0/16 outgoing' > /smack/netlabel
		    echo '0.0.0.0/0 bankcfg' > /smack/netlabel
		else
		    echo '0.0.0.0/0 outgoing' > /smack/netlabel
		fi
            fi
	fi
    ;;
esac

# END		
