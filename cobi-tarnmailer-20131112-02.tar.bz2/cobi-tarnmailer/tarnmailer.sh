#!/bin/bash
# encoding: utf-8

maildirs=` find $HOME/.thunderbird -type d -maxdepth 2 -name Mail | wc -l ` 
if [ "$maildirs" -lt 1 ] ; then
	zenity --error --text "Falls Sie die vom COMPUTER BILD Tarnmailer aus direkt E-Mails verschicken wollen, konfigurieren Sie bitte jetzt das E-Mail-Programm Thunderbird. Andernfalls schlieﬂen Sie Thunderbird einfach." 
	# exit 1
fi
thunderbird &
ruby /usr/share/lesslinux/cobi-tarnmailer/tarnmailer.rb 
