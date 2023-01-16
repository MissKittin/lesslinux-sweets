#!/static/bin/ash
		
#lesslinux provides local
#lesslinux license BSD
#lesslinux description
# Run local startup scripts
# 
# Overlays may be stored as same_filename.tgz in the same folder as an ISO
# or as overlay.tgz in the directory with the squashfs containers. If both
# exist, the overlay among the ISO overwrites files. More possibliities 
# like http://, ftp:// or tftp:// might follow soon.
#
# Please also take a look at /etc/rc.d/0148-overlay.sh
#
# Since the init process already knows all scripts in /etc/rc.d, scripts
# to this folder added with an overlay will not be executed. For now, 
# overwrite this script in your overlay, treat this as a template.
# A better possibility in form of an /etc/rc.local.d/ might follow.

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	# printf "$bold===> Starting locals scripts $normal\n"
	exit 0
    ;;
    stop)
	# printf "$bold===> Stopping locals scripts $normal\n"
	exit 0
    ;;
esac
	
		
