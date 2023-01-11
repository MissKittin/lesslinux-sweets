#!/bin/bash
# encoding: utf-8

/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc
uuid=` uuidgen `
outdir=/tmp/${uuid}
mkdir $outdir
cd $outdir 
wget http://cdprojekte.mattiasschlenker.de/woa/woa.tgz
wget http://cdprojekte.mattiasschlenker.de/woa/woa.tgz.asc

if [ -f woa.tgz.asc ] ; then
	echo 'file found, continue'
else
	zenity --error --text "Der Download des Windows-Office-Aktualisierers ist fehlgeschlagen. Prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut."
	exit 1
fi

if /usr/bin/gpg --verify woa.tgz.asc ; then
	tar xvzf woa.tgz
	bash RUNME.sh
else
	zenity --error --text "Die Integrität des Windows-Office-Aktualisierers konnte nicht überpüft werden. Abbruch."
	exit 1
fi
