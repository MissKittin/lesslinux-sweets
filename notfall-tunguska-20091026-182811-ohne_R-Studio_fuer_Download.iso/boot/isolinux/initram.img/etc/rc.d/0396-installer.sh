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
	/usr/bin/xinit "$XINITRC" -- /usr/bin/Xvesa -br +kb -keybd keyboard -mouse mouse,/dev/input/mice -mode "$tryvesa" 2> /dev/null
    ;;
esac

# The End  
