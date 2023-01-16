#!/static/bin/ash
		
#lesslinux provides xconfgui
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

XINITRC=/usr/local/xconfgui/xinitrc

case $1 in 
    start)
	printf "$bold===> Starting configuration interface $normal\n"
	# dump vesa modes
	Xvesa -listmodes > /tmp/.vesamodes 2>&1
	# Search suitable modes
	resolutions="640x480x16 800x480x16 800x600x16 1024x768x16"
	tryvesa=0x0111
	for i in $resolutions ; do
		mode=` grep " $i " /tmp/.vesamodes | awk -F ':' '{print $1}' `
		[ -n "$mode" ] && tryvesa="$mode"
	done
	# LANG=de_DE.UTF-8 ; export LANG
	if echo "$skipservices" | grep '|monitortest|' ; then
            echo "===> Skipping monitor test"
	else
	    # First start the monitor test with the normal Xorg server
	    /usr/bin/xinit /usr/local/xconfgui/monitortest -- /usr/bin/Xorg -br -dpi "$dpi"
	fi
	# Second start the Xvesa server with the generic xinitrc script
	if [ -f /var/run/lesslinux/xconfgui_xorg ] ; then
	    /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -br -dpi "$dpi"
	else
	    /usr/bin/xinit "$XINITRC" -- /usr/bin/Xvesa -br +kb -keybd keyboard -mouse mouse,/dev/input/mice -mode "$tryvesa"
	fi
    ;;
esac

# The end	
