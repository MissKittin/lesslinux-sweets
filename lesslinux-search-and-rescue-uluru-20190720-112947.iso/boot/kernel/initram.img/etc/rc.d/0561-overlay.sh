#!/static/bin/ash
		
#lesslinux provides cryptovrl
#lesslinux license BSD
#lesslinux description
# Unpack overlays if found
 
# Overlays may be stored as same_filename.tgz in the same folder as an ISO
# or as overlay.tgz in the directory with the squashfs containers. If both
# exist, the overlay among the ISO overwrites files. More possibliities 
# like http://, ftp:// or tftp:// might follow soon.
#
# Please also take a look at /etc/rc.d/9999-local.sh

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	printf "$bold===> Searching overlays... $normal\n"
	for i in 0 1 2 3 4 5 6 7 8 9 ; do
		tar -C / -xzf /lesslinux/cryptpart/overlays/overlay${i}.tgz 2> /dev/null  
	done
    ;;
esac
	
		
