#!/static/bin/ash
		
#lesslinux provides devel
#lesslinux license BSD
#lesslinux description
# Prepare development and build environment of LessLinux

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	if [ -x /usr/share/lesslinux/auxiliary-scripts/prepare-lesslinux-build.sh ] ; then
		printf "$bold===> Preparing development environment... $normal\n"
		/usr/share/lesslinux/auxiliary-scripts/prepare-lesslinux-build.sh
		if [ -f /mnt/archiv/LessLinux/development_overlays.tar.gz ] ; then
			tar -C / -xzf /mnt/archiv/LessLinux/development_overlays.tar.gz
		fi
	fi
    ;;
esac
	
		
