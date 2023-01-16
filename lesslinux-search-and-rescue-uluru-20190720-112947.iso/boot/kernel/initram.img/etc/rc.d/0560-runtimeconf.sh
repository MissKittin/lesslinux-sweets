#!/static/bin/ash
		
#lesslinux provides runtimeconf
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

XINITRC=/usr/local/xconfgui/xinitrc_runtimeconf

case $1 in 
    start)
	HOME=/root
	export HOME
	mkdir -p -m 0600 /root 
	printf "$bold===> Starting configuration interface $normal\n"
	if [ -n "$xvfb" ] ; then
	    touch /var/run/lesslinux/skip_monitortest
	elif echo "$skipservices" | grep '|monitortest|' ; then
	    touch /var/run/lesslinux/skip_monitortest
	elif fbset > /dev/null 2>&1 && cat /proc/cmdline | grep -qv ' vga=' && [ -z "$xvfb" ] ; then
	    touch /var/run/lesslinux/skip_monitortest
	    touch /var/run/lesslinux/xconfgui_xorg
	    touch /var/run/lesslinux/xconfgui_skip_monitor
	elif lspci -n | grep -iq '15ad:0405' && [ -z "$xvnc" ] ; then 
	    touch /var/run/lesslinux/skip_monitortest
	    touch /var/run/lesslinux/xconfgui_xorg
	    touch /var/run/lesslinux/xconfgui_skip_monitor
	    touch /var/run/lesslinux/vmware_detected
	fi
	
	# FIXME: Starting the Xserver twice is needed on some Ati cards with Kernel 3.10.5
	# This behaviour might be fixed with later kernel or firmware versions
	# if [ -z "$xvfb" ] ; then
	#	scrn=""
	#	[ -n "$xorgscreen" ] && scrn="-screen $xorgscreen"
	#	/usr/bin/xinit /usr/bin/Esetroot /usr/local/xconfgui/testbild.png -- /usr/bin/Xorg -retro -nolisten tcp $scrn -br -dpi "$dpi"
	#	/usr/bin/xinit /usr/bin/Esetroot /usr/local/xconfgui/testbild.png -- /usr/bin/Xorg -retro -nolisten tcp $scrn -br -dpi "$dpi"
	# fi
	
	# Remove an old indicator
	rm ${HOME}/.lesslinux/xsetroot_successful
	
	# The Xorg server crashes on some ATI cards, try to show a quick progressbar on those and fallback to
	# framebuffer X when failed:
	
	if [ -z "$xvfb" ] ; then
		if [ -n "$xorgscreen" ] ; then
			/usr/bin/xinit /usr/local/xconfgui/pgbar -- /usr/bin/Xorg -retro -nolisten tcp -screen "$xorgscreen" -br -dpi "$dpi"
		else
			/usr/bin/xinit /usr/local/xconfgui/pgbar -- /usr/bin/Xorg -retro -nolisten tcp -br -dpi "$dpi"
		fi
		if [ -f /var/run/lesslinux/display_opened_successfully ] ; then
			echo "OK, display opened successfully..."
			mkdir ${HOME}/.lesslinux
			touch ${HOME}/.lesslinux/xsetroot_successful
		elif [ -c /dev/fb0 ] ; then
			cp -v /etc/X11/xorg.conf.fbdev /etc/X11/xorg.conf
		else
			cp -v /etc/X11/xorg.conf.vesa /etc/X11/xorg.conf
		fi
	fi
	
	if [ -f /var/run/lesslinux/skip_monitortest ] ; then
	    echo "===> Skipping monitor test"
	else
	    ## First start the monitor test with the normal Xorg server
	    ## If an alternative xorg.conf has been copied this is used 
	    ## The cheatcode for using a certain section in xorg.conf is 
	    ## already active
	    if [ -n "$xorgscreen" ] ; then
		/usr/bin/xinit /usr/local/xconfgui/monitortest -- /usr/bin/Xorg -retro -nolisten tcp -screen "$xorgscreen" -br -dpi "$dpi"
	    else
		/usr/bin/xinit /usr/local/xconfgui/monitortest -- /usr/bin/Xorg -retro -nolisten tcp -br -dpi "$dpi"
	    fi
	fi
	
	if [ -f /var/run/lesslinux/xorg_vars ] ; then
		. /var/run/lesslinux/xorg_vars
	fi

	

	if [ -n "$xvfb" ] ; then
		# xvfb=WIDTHxHEIGHTxDEPTH
		/usr/bin/xinit "$XINITRC" -- /usr/bin/Xvfb :0 -retro -nolisten tcp -dpi "$dpi" -screen :0 "$xvfb"
		echo "$xvfb" >> /var/run/lesslinux/runtimeconf
	else
		# Determine if we have to use a screen section or not - do not use a screen section when KMS is detected
		if [ -c /dev/fb0 ] && cat /proc/cmdline | grep -qv ' vga=' ; then
			echo "kms" >> /var/run/lesslinux/runtimeconf
			# Use the framebuffer X server in this case, to make sure the right resolution is used
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -nolisten tcp -br -dpi "$dpi"
			# /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -config xorg.conf.fbdev -nolisten tcp -br -dpi "$dpi"
		elif [ -n "$xorgscreen" -a -f /etc/X11/xorg.conf ] ; then
			echo "screen section" >> /var/run/lesslinux/runtimeconf
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -nolisten tcp -screen "$xorgscreen" -br -dpi "$dpi"
		else
			echo "try xorgconf" >> /var/run/lesslinux/runtimeconf
			/usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -nolisten tcp -br -dpi "$dpi"
		fi
		if [ '!' -f ${HOME}/.lesslinux/xsetroot_successful -a -f /etc/xinitrc.d/0000-xsetroot.sh ] ; then
			if [ -c /dev/fb0 ] ; then
				echo "framebuffer" >> /var/run/lesslinux/runtimeconf
				/usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -config xorg.conf.fbdev -nolisten tcp -br -dpi "$dpi"
			else
				echo "vesa" >> /var/run/lesslinux/runtimeconf
				/usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -config xorg.conf.vesa -nolisten tcp -br -dpi "$dpi"
			fi
		fi
	fi
	
	if [ -p /splash.fifo ] ; then
		echo "exit" > /splash.fifo
		chvt 8
		# Remove old fifo
		rm /splash.fifo
		# Create new (empty fifo)
		mkfifo /splash.fifo
		fbsplash -i /etc/lesslinux/fbsplash.cfg -s /etc/lesslinux/branding/fbsplash/splash.ppm -f /splash.fifo &
	fi
	
	# FIXME! Move blobsearch to a separate function
	# FIXME! Newer files should win!
	if [ -d "/lesslinux/cryptpart/${contdir}/blob" ] ; then
		mkdir -p /lesslinux/blob
		find "/lesslinux/cryptpart/${contdir}/blob" -maxdepth 1 | while read fname ; do
			[ -f "$fname" -o -d "$fname" ] && \
				ln -sf "$fname" /lesslinux/blob/` basename "$fname" ` 
		done
	fi
    ;;
esac

# The end	
