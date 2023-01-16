#!/static/bin/ash
		
#lesslinux provides ffuser
#lesslinux license BSD

PATH=/usr/bin:/usr/sbin:/bin:/sbin:/static/bin:/static/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
[ -f /etc/default/browser ] && . /etc/default/browser

expiration=20130101
ffversion=` grep -E '\sfirefox\s' /etc/lesslinux/pkglist.txt | awk '{print $3}' ` 
shortversion=` echo $ffversion | sed 's%esr%%g' ` 

case $1 in 
    start)
	if [ -d ${HOME}/.mozilla/firefox ] ; then
		profdir=` cat ${HOME}/.mozilla/firefox/profiles.ini | grep '^Path' | head -n1 | awk -F '=' '{print $2}' ` 
		mkdir -p ${HOME}/.mozilla/firefox/${profdir}/extensions/ 
		ffversion=` cat /etc/lesslinux/pkglist.txt | grep '\sfirefox\s' | awk '{print $3}' ` 
		for packlang in de es-ES pl ru fr it nl pt-PT da lt lv et sk sl sv-SE bg hr nb-NO ro sr tr cs hu fi el  ; do
			ln -sf /opt/firefox-${ffversion}-extensions/firefox-${shortversion}.${packlang}.langpack.xpi \
			${HOME}/.mozilla/firefox/${profdir}/extensions/langpack-${packlang}'@firefox.mozilla.org'.xpi
		done
	fi
	# DEFAULT_HOMEPAGE should be set in /etc/default/browser
	# homepage can be set via cheatcode homepage=http://blog.lesslinux.org/ at boot time
	if [ -n "$DEFAULT_HOMEPAGE" ] ; then
		find $HOME/.mozilla/firefox -maxdepth 2 -name prefs.js | while read fname ; do
			echo 'user_pref("browser.startup.homepage", "'"$DEFAULT_HOMEPAGE"'");'  >> $fname
		done
	fi
	find $HOME/.mozilla/firefox -maxdepth 2 -name prefs.js | while read fname ; do
		if [ -n "$homepage" ] ; then
			echo 'user_pref("browser.startup.homepage", "'"$homepage"'");' >> $fname
		fi
		# echo 'user_pref("browser.startup.homepage_override.mstone", "rv:'$ffversion'");' >> $fname
		# echo 'user_pref("extensions.lastAppVersion", "'$ffversion'");' >> $fname
		# echo 'user_pref("extensions.lastPlatformVersion", "'$ffversion'");' >> $fname
		# sed -i 's/\:10\.0\.2/:'$ffversion'/g' $fname
	done
    ;;
esac

		
