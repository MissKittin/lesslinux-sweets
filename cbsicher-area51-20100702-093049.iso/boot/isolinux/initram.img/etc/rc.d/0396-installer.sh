#!/static/bin/ash

#lesslinux provides installer
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

XINITRC=/usr/local/xconfgui/xinitrc_installer

case $1 in 
    start)
	printf "$bold===> Starting installer interface $normal\n"
	# cp -f /etc/X11/xorg.conf.xorg /etc/X11/xorg.conf
	# FIXME: the xorg.conf.vesa should be copied by providing the appropriate boot parameter 
	# cp -f /etc/X11/xorg.conf.vesa /etc/X11/xorg.conf
	if [ -n "$xorgscreen" ] ; then
	    /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen "$xorgscreen" -br -dpi "$dpi"
	else
	    /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -br -dpi "$dpi"
	fi
	### FIXME: Choose one of those as fallback?
	### /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen Screen_TFT_1024x768 -br -dpi "$dpi"
	### /usr/bin/xinit "$XINITRC" -- /usr/bin/Xorg -screen default_screen -br -dpi "$dpi"
    ;;
esac

# The End  
