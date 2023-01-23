#!/bin/ash
# encoding: utf-8

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

install -m 0755 1111-fixes.sh /etc/rc.d
mountpoint -q /usr/share/lesslinux/drivetools/accesspoint.rb || mount --bind accesspoint.rb /usr/share/lesslinux/drivetools/accesspoint.rb
DISPLAY=:0 xrdb -merge xvkbd.xrdb
install -m 0644 xvkbd.xrdb /home/surfer/.lesslinux/xvkbd.xrdb
chown surfer:surfer /home/surfer/.lesslinux/xvkbd.xrdb

if [ "$1" = "--quiet" ] ; then
	echo 'DEBUG: Der Updater wurde mit dem switch --quiet aufgerufen.'
else
	/usr/bin/zenity --info --text 'Updates wurden installiert für: Bildschirmtastatur und WLAN Accesspoint.'
fi
