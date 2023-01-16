#!/static/bin/ash
		
#lesslinux provides tbuser
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/default/mailer ] && . /etc/default/mailer

ffversion=` grep -E '\sthunderbird\s' /etc/lesslinux/pkglist.txt | awk '{print $3}' ` 
shortversion=` echo $ffversion | sed 's%esr%%g' ` 

case $1 in 
    start)
	if [ -d ${HOME}/.thunderbird ] ; then
		profdir=` cat ${HOME}/.thunderbird/profiles.ini | grep '^Path' | head -n1 | awk -F '=' '{print $2}' ` 
		mkdir -p ${HOME}/.thunderbird/${profdir}/extensions/ 
		for packlang in de es-ES pl ru fr it nl pt-PT da lt lv et sk sl sv-SE bg hr nb-NO ro sr tr cs hu fi el  ; do
			ln -sf /usr/share/mozilla-localization/thunderbird-${shortversion}.${packlang}.langpack.xpi \
			${HOME}/.thunderbird/${profdir}/extensions/langpack-${packlang}'@thunderbird.mozilla.org'.xpi
		done
	fi
    ;;
esac

		
