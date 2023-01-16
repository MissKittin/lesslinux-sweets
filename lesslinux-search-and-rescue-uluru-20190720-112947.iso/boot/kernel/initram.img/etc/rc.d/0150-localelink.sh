#!/static/bin/ash
		
#lesslinux provides loli
#lesslinux license BSD
#lesslinux description
# Link some locale defaults

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

case $1 in
    start)
	printf "$bold===> Linking some localization settings... $normal\n"
	cat /etc/lesslinux/branding/filelist.txt | while read fname ; do
		[ -n "$fname" ] && [ -f "${fname}.en" ] && ln -sf "${fname}.en" "$fname"
		[ -n "$fname" ] && [ -f "${fname}.${lang}" ] && ln -sf "${fname}.${lang}" "$fname"
	done
    ;;
esac
	
		
