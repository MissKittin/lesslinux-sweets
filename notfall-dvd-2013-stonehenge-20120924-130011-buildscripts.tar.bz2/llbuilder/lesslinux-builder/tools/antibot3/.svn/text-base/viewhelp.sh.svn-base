#!/bin/bash
# encoding: utf-8

helpfile="/lesslinux/cdrom/Antibot.3.0.pdf"

for d in isoloop cdrom toram antibot ; do
	for e in antibot3/ / ; do
		[ -f "/lesslinux/${d}/${e}Antibot.3.0.pdf" ] && helpfile="/lesslinux/${d}/${e}Antibot.3.0.pdf"
	done
done

if [ -f "$helpfile" ] ; then
	exec evince "$helpfile"
else
	exec zenity --error --text "Entschuldingung, die Hilfedatei ${helpfile} wurde nicht gefunden."
fi
