#!/static/bin/ash
		
#lesslinux provides tb
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

tbversion=` grep -E '\sthunderbird\s' /etc/lesslinux/pkglist.txt | awk '{print $3}' ` 

case $1 in 
    start)
	printf "$bold===> Preparing Thunderbird $tbversion $normal\n"
	for f in /etc/sudoers.lax.d/thunderbird /etc/sudoers.strict.d/thunderbird ; do
		sed -i 's/THUNDERBIRDVERSION/'"$tbversion"'/g' ${f} 
		chmod 0440 ${f}
	done
    ;;
esac

		
