#!/bin/bash
# encoding: utf-8

restfile="$1"
target="${restfile%.antibot3}"

md5=` md5sum -b "$target" | awk '{print $1}' `

if [ -z "$restfile" ] ; then
	zenity --error --text "Sie müssen eine Datei angeben, die wiederhergestellt werden soll!"
	exit 1
fi
if [ "$restfile" = "$target" ] ; then
	zenity --error --text "Die angegebene Datei muss auf .antibot3 enden!"
	exit 1
fi
zenity --question --text "Wollen Sie die Datei $target aus der verschlüsselten Sicherungsdatei wiederherstellen?" || \
		exit 1
if [ -f "$target" ] ; then
	echo $md5
	[ "$md5" = "d41d8cd98f00b204e9800998ecf8427e" ] || \
		zenity --question --text "Die Zieldatei ist nicht leer, möglichwerweise wurde sie mit einer reparierten Version ersetzt. Wollen Sie dennoch weitermachen?" || \
		exit 1
fi

res=1
( echo "los gehts" ; openssl enc -d -aes-128-cbc -k AntiBot3.0 -in "$restfile" -out "$target" ; echo -n $? > /var/run/lesslinux/restorebak.ret ) | \
	zenity --progress --no-cancel --pulsate --auto-close --text "Die Datei ${target} wird wiederhergestellt. Bitte haben Sie etwas Geduld."
[ -f /var/run/lesslinux/restorebak.ret ] && res=` cat /var/run/lesslinux/restorebak.ret `
if [ "$res" -gt 0 ] ; then
	zenity --error --text "Die Wiederherstellung war nicht erfolgreich. Die verschlüsselte Sicherungsdatei wird nicht gelöscht."
	exit 1
else
	zenity --question --text "Die Wiederherstellung war erfolgreich. Soll die verschlüsselte Sicherungsdatei gelöscht werden?" && rm -f "${restfile}"
	exit 0
fi
