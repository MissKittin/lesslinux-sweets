#!/bin/bash

/AntiVirUpdate/avupdate > /var/log/avupdate.log 2>&1
retval=$?
if [ "$retval" -lt 2 ] ; then
	touch /AntiVir/rescue_cd.key
fi
echo $retval > /var/log/avupdate.ret
sleep 2
