#!/static/bin/ash
		
#lesslinux provides blob
#lesslinux license BSD
#lesslinux description
# Search the partition containing blobs

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
		
case $1 in
    start)
	mkdir -p /lesslinux/blob
	for dir in cdrom toram isoloop ; do
		if [ -d "/lesslinux/${dir}/${contdir}/blob" ] ; then
			find "/lesslinux/${dir}/${contdir}/blob" -maxdepth 1 | while read fname ; do
				[ -f "$fname" -o -d "$fname" ] && \
					ln -sf "$fname" /lesslinux/blob/` basename "$fname" ` 
			done
		fi
	done
	if mountpoint -q /lesslinux/cryptpart ; then
		if [ -d /lesslinux/cryptpart/blob ] ; then
			find "/lesslinux/cryptpart/blob" -maxdepth 1 | grep -v '/lesslinux/cryptpart/blob$' | while read fname ; do
				[ -f "$fname" -o -d "$fname" ] && \
					ln -sf "$fname" /lesslinux/blob/` basename "$fname" ` 
			done
		fi
	fi
	if  mountpoint -q /lesslinux/blobpart ; then
		find "/lesslinux/blobpart" -maxdepth 1 | grep -v '/lesslinux/blobpart$' | while read fname ; do
			[ -f "$fname" -o -d "$fname" ] && \
					ln -sf "$fname" /lesslinux/blob/` basename "$fname" ` 
		done
	fi
    ;;
esac

