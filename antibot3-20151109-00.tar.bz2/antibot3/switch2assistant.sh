#!/bin/bash
# encoding: utf-8

case $LANG in 
	de*)
		message='Achtung! Beim Wechsel zum Assistenten werden alle Anwendungen beendet. Nicht gespeicherte Daten gehen verloren. Wollen Sie wirklich zum Assistenten wechseln?'
	;; 
	*)
		message='Warning! When switching to the assistant, all applications will be closed. Unsaved data might be lost. Do you really want to switch to the assistant?'
	;;
esac

if zenity --question --text "$message" ; then
	killall -9 xinit
else
	exit 1
fi
ps waux | while read line ; do
	pid=` echo $line | awk '{print $2}' `
	proc=` echo $line | awk '{print $11}' `
	if [ "$proc" = /usr/bin/Xorg -o "$proc" = /usr/bin/Xvfb -o "$proc" = /usr/libexec/Xorg -o "$proc" = /usr/libexec/Xvfb ] ; then
		kill $pid
		sleep 1
		kill -9 $pid
	fi
done
