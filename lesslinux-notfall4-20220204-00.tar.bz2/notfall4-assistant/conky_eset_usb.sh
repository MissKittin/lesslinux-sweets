#!/bin/bash

usbinfo="Signatures on USB"
raminfo="Signatures in RAM"

case $lang in
	de*)
		usbinfo="Signaturen auf USB"
		raminfo="Signaturen im RAM"
	;;
esac
	

if mountpoint -q /lesslinux/blobpart && [ -d /lesslinux/blobpart/eset/lib/ -a -x /opt/eset/esets/sbin/esets_daemon ] ; then
	echo "$usbinfo"
elif [ -x /opt/eset/esets/sbin/esets_daemon ] ; then
	echo "$raminfo"
elif mountpoint -q /lesslinux/blobpart && [ -d /lesslinux/blobpart/ClamAV/ ] ; then
	echo "$usbinfo"
else
	echo "$raminfo"
fi
