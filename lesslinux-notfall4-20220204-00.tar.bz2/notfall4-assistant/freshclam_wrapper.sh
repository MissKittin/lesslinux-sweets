#!/bin/bash

mkdir -p /var/log/freshclam
chown -R clamav:clamav /var/log/freshclam
rm /var/log/freshclam/freshclam.log

/opt/bin/freshclam --log=/var/log/freshclam/freshclam.log
retval=$?
if [ "$retval" -lt 1 ] ; then
	touch /opt/share/clamav/main.cvd
fi
echo $retval > /var/log/freshclam.ret
sleep 2
