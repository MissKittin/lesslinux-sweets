#!/bin/bash
# encoding: utf-8

case $LANG in 
	de*)
		message='Achtung! Im Moment läuft eine Suche nach Schadsoftware. Brechen Sie diese ab, erst dann ist der Wechsel in den Desktop-Modus möglich!'
	;; 
	*)
		message='Warning! Currently the search for malicious software is running. Cancel this action before witching to the desktop mode is possible!'
	;;
esac

if [ -f /var/run/lesslinux/scan_running ] ; then
	zenity --error --text "$message"
	exit 1
fi
touch /home/surfer/.ll_requested_desktop
ps waux | while read line ; do
	pid=` echo $line | awk '{print $2}' `
	proc=` echo $line | awk '{print $11}' `
	if [ "$proc" = /usr/bin/Xorg -o "$proc" = /usr/bin/Xvfb -o "$proc" = /usr/libexec/Xorg -o "$proc" = /usr/libexec/Xvfb ] ; then
		kill $pid
		sleep 1
		kill -9 $pid
	fi
done
