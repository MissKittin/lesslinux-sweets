#!/bin/bash

if dropbox status | grep -Eq 'Idle|Uploading|Downloading' ; then
	echo "=> DropBox is running and connected - execute nautilus"
	exec nautilus --no-desktop /home/surfer/Dropbox
fi

[ -d /home/surfer/Dropbox ] || mkdir Dropbox

if [ -x /home/surfer/.dropbox-dist/dropboxd ] ; then
	echo "=> DropBox seems to be installed - skipping installation"
else
	echo "=> Installing DropBox first - you might consider reading README.dropbox.txt in the blob folder"
	dropbox start -i
fi
dropbox stop > /dev/null 2>&1
[ -f /tmp/dropbox.log ] && rm /tmp/dropbox.log
echo "=> Starting dropbox daemon"
/home/surfer/.dropbox-dist/dropboxd > /tmp/dropbox.log &
sleep 3
machineid=`  sqlite3 /home/surfer/.dropbox/config.db 'select value from config where key="host_id" ' ` 
connected=0

if [ -z "$machineid" ] ; then
	sleep 3
	url=` grep '^Please visit' /tmp/dropbox.log | awk '{print $3}' | head -n1 `
	exo-open "$url"
else
	exo-open 'https://www.dropbox.com/cli_link?host_id='"$machineid"
fi

while [ "$connected" -lt 1 ] ; do
	sleep 3
	if grep -q 'Client successfully linked' /tmp/dropbox.log ; then
		connected=1
	fi
	if dropbox status | grep -Eq 'Idle|Uploading|Downloading' ; then
		connected=1
	fi
done
nautilus --no-desktop /home/surfer/Dropbox
