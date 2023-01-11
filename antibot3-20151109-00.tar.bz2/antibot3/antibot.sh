#!/bin/bash

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin:/opt/bin:/opt/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

# export LANGUAGE=de_DE:de 
# export LC_ALL=de_DE.UTF-8
# export LANG=de_DE.UTF-8

cd ` dirname "$0" `
# esetroot -s antibot3_black.png 
mkdir -p /var/log/antibot3
mkdir -p /tmp/Protokolle
mkdir -p /tmp/scan-log
rm /var/run/lesslinux/scan_running
tstamp=` date +%Y%m%d-%H%M%S `
# ping -c1 de.pool.ntp.org && ntpd -n -q -p de.pool.ntp.org
ruby -I. -I../drivetools antibot.rb $@ > /var/log/antibot3/antibot3-${tstamp}.log 2>&1
