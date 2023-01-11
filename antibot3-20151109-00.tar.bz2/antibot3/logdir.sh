#!/bin/bash
# encoding: utf-8

case $LANGUAGE in 
	de*)
		[ -d /lesslinux/antibot/antibot3/Protokolle ] && exec Thunar /lesslinux/antibot/antibot3/Protokolle
		[ -d /tmp/Protokolle ] && exec Thunar /tmp/Protokolle
	;;
	*)
		[ -d /lesslinux/antibot/antibot3/scan-log ] && exec Thunar /lesslinux/antibot/antibot3/scan-log
		[ -d /tmp/scan-log ] && exec Thunar /tmp/scan-log
	;;
esac
