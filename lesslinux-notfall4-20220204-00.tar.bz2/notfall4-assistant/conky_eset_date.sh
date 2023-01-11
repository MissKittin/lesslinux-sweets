#!/bin/bash
tstyle='+%d.%m.%Y_%H:%M'
if [ -x /opt/eset/esets/sbin/esets_daemon ] ; then
	ls -lhtr --time-style="$tstyle" "/var/opt/eset/esets/lib/" | grep '.dat$' | tail -n1 | awk '{print $6}' | sed 's/_/ - /g'
else
	ls -lhtr --time-style="$tstyle" "/opt/share/clamav/" | tail -n1 | awk '{print $6}' | sed 's/_/ - /g'
fi
