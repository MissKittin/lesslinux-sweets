#!/bin/bash

/opt/eset/esets/etc/init.d/esets stop
sleep 2
/opt/eset/esets/etc/init.d/esets start
/opt/eset/esets/sbin/esets_daemon --update
# Enough time to download the update definition 
sleep 30
completed=0
rounds=0
echo 0 > /var/log/eset_update.log
latestfile=`ls -tr /mnt/eset-live-rw/lib/ | grep -e '\.dat$' | tail -n1 `
if [ "/mnt/eset-live-rw/lib/${latestfile}" -nt /var/run/lesslinux/install_source ] ; then
	sleep 120
else
	sleep 300
	# touch "/mnt/eset-live-rw/lib/${latestfile}"
fi
