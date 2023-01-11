#!/bin/bash

# Change search path:

export PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin:$PATH  

buildid=` cat /etc/lesslinux/updater/version.txt ` 
mkdir -p /cobi

# ifconfig eth0:3 inet 169.254.1.222 netmask 255.255.0.0
esetroot -scale /etc/lesslinux/branding/desktop_de.png

if [ -x /lesslinux/blobpart/lesslinux.update/${buildid}/notfallcd4/assistant.sh ] ; then
	exec /bin/bash /lesslinux/blobpart/lesslinux.update/${buildid}/notfallcd4/assistant.sh
elif [ -x /tmp/lesslinux.update/notfallcd4/assistant.sh ] ; then
	exec /bin/bash /tmp/lesslinux.update/notfallcd4/assistant.sh
fi

cd /usr/share/lesslinux/notfallcd4
if [ -d /lesslinux/blobpart/lesslinux.update/${buildid}/notfallcd4 ] ; then
	ruby -I/lesslinux/blobpart/lesslinux.update/${buildid}/notfallcd4 -I/usr/share/lesslinux/drivetools assistant-ng.rb  $@ 
elif [ -d /tmp/lesslinux.update/notfallcd4 ] ; then
	ruby -I/tmp/lesslinux.update/notfallcd4 -I/usr/share/lesslinux/drivetools assistant-ng.rb  $@ 
else
	ruby -I. -I/usr/share/lesslinux/drivetools assistant-ng.rb  $@ 
fi
