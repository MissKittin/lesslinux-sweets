#!/static/bin/ash
		
PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/rc.subr/progressbar

mountpoint -q /lesslinux/blobpart || exit 0
mkdir -p /lesslinux/blobpart/ClamAV
touch /lesslinux/blobpart/ClamAV/.install_here

#		
