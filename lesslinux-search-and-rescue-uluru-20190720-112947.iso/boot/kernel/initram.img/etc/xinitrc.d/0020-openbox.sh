#!/bin/bash
#lesslinux provides obmenu

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
		
. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

x11vnc=''
conn=''
pass=''
parg=''

case $1 in start)
	if [ -f ${HOME}/.config/openbox/menu.xml ] ; then
		echo "menu.xml exists, exiting."
		exit 0
	fi
	menu=""
	[ -f /usr/share/lesslinux/openbox/menu.xml ] && menu="/usr/share/lesslinux/openbox/menu.xml"
	[ "$xinitrc" = "/etc/lesslinux/xinitrc_remote" ] && [ -f /usr/share/lesslinux/openbox/menu_thin.xml ] && menu="/usr/share/lesslinux/openbox/menu_thin.xml"
	[ -f /etc/lesslinux/branding/openbox_menu.xml ] && menu="/etc/lesslinux/branding/openbox_menu.xml"
	if [ -z "$menu" ] ; then
		echo "No template for menu.xml found, exiting."
		exit 1
	fi
	trans=""
	[ -f /usr/share/lesslinux/openbox/menu_translations.xml ] && trans="/usr/share/lesslinux/openbox/menu_translations.xml"
	[ -f /etc/lesslinux/branding/openbox_menu_translations.xml ] && trans="/etc/lesslinux/branding/openbox_menu_translations.xml"
	if [ -z "$trans" ] ; then
		echo "No translations for menu.xml found, exiting."
		exit 1
	fi
	mkdir -p ${HOME}/.config/openbox
	ruby /usr/share/lesslinux/openbox/substitute_menu.rb "$menu" "${HOME}/.config/openbox/menu.xml" "$trans"
   ;;
esac

		
