#!/bin/bash
#lesslinux provides langsel

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
		
. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
 
case $1 in start)
	if [ "$UID" -lt 1 ] ; then
		# Try to query VirtualBox for host language 
		if [ -x /usr/local/VirtualBox-guest/additions/VBoxControl -a -z "$xlocale" ] ; then
			vboxlocale=` /usr/local/VirtualBox-guest/additions/VBoxControl guestproperty get /VirtualBox/HostInfo/GUI/LanguageID | grep -i value | awk '{print $2}' `  
			case "$vboxlocale" in
				*_*)
					nolangsel=1
					xlocale=${vboxlocale}.UTF-8
					echo "xlocale=${xlocale} nolangsel=1" >> /etc/lesslinux/cmdline
				;;
			esac
		fi 
		if [ "$nolangsel" -gt 0 -o -n "$xlocale" ] ; then
			echo "Skipping language selection"
		else
			/usr/bin/ruby -I /usr/share/lesslinux/drivetools /usr/local/xconfgui/langselect.rb
			. /etc/rc.subr/extractbootparams
			if [ "$xkbmap" = "ru" ] ; then
				setxkbmap -layout us,ru -variant ,winkeys -option grp:alt_shift_toggle,grp_led:scroll
			else
				setxkbmap -layout "$xkbmap"
			fi
		fi
	fi
;;
esac

		
