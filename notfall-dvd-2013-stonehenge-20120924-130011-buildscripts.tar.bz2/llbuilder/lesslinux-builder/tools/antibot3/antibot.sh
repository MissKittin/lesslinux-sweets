#!/bin/bash

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

export LANGUAGE=de_DE:de 
export LC_ALL=de_DE.UTF-8
export LANG=de_DE.UTF-8

cd ` dirname "$0" `
esetroot -s antibot3_black.png 
mkdir -p /var/log/antibot3
mkdir -p /tmp/Protokolle
tstamp=` date +%Y%m%d-%H%M%S `
# ping -c1 de.pool.ntp.org && ntpd -n -q -p de.pool.ntp.org
ruby -I. antibot.rb $@ > /var/log/antibot3/antibot3-${tstamp}.log 2>&1

