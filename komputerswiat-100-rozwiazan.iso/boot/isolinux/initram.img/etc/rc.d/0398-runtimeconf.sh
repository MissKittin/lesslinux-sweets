#!/static/bin/ash
		
#lesslinux provides runtimeconf
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

XINITRC=/usr/local/xconfgui/xinitrc_runtimeconf

case $1 in 
    start)
	printf "$bold===> Starting configuration interface $normal\n"
	if echo "$skipservices" | grep '|monitortest|' || [ -n "$xvnc" ]; then
            echo "===> Skipping monitor test"
	else
	    ## First start the monitor test with the normal Xorg server
	    ## If an alternative xorg.conf has been copied this is used 
	    ## The cheatcode for using a certain section in xorg.conf is 
	    ## already active
	    if [ -n "$xorgscreen" ] ; then
		/usr/bin/xinit /usr/local/xconfgui/monitortest -- /usr/bin/Xorg -screen "$xorgscreen" -br -dpi "$dpi"
	    else
		/usr/bin/xinit /usr/local/xconfgui/monitortest -- /usr/bin/Xorg -br -dpi "$dpi"
	    fi
	fi
	
	if [ -f /var/run/lesslinux/xconfgui_xorg ] && [ -z "$xvnc" ] ; then
	    ## The usage of the Xorg.conf copied above seems to have succeeded, use it!
	    ## Some fine adjustments can be made later
	    if [ -n "$xorgscreen" ] ; then
	        /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen "$xorgscreen" -br -dpi "$dpi"
	    else
	        /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -br -dpi "$dpi"
	    fi
	else
	    if [ -z "$xvnc" ] ; then
	        ## The usage of the Xorg.conf copied above seems to have failed, fall back to the
	        ## VESA configuration instead for runtimeconf, try 1024x768
	        cp -f /etc/X11/xorg.conf.vesa /etc/X11/xorg.conf
	        /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen Screen_TFT_1024x768 -br -dpi "$dpi"
	        ### Maybe this is better?
	        ### /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen default_screen -br -dpi "$dpi"
	    else
		# xvnc=|local/remote|resolution|depth|
		vncmode=` echo "$xvnc" | awk -F '|' '{print $2}' `
		vncres=` echo "$xvnc" | awk -F '|' '{print $3}' `
		vncdepth=` echo "$xvnc" | awk -F '|' '{print $4}' `
		if [ "$vncmode" = "remote" ] ; then 
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xvnc -geometry "$vncres" -depth "$vncdepth" -dpi "$dpi"
		elif [ "$vncmode" = "reverse" ] ; then
			revhost=` echo "$xvnc" | awk -F '|' '{print $5}' `
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xvnc -interface 127.0.0.1 -geometry "$vncres" -depth "$vncdepth" -dpi "$dpi" &
			sleep 5
			/usr/bin/vncconnect -display :0 "$revhost"
			while ps waux | grep -q /usr/bin/xinit ; do
				sleep 10
			done
		else
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xvnc -interface 127.0.0.1 -geometry "$vncres" -depth "$vncdepth" -dpi "$dpi"
		fi
	    fi
	fi
    ;;
esac

# The end	
