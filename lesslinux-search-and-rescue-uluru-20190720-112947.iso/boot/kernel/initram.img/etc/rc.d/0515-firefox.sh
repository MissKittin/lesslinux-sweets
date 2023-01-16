#!/static/bin/ash
		
#lesslinux provides ff
#lesslinux license BSD

PATH=/static/bin:/static/sbin:/bin:/sbin:/usr/bin:/usr/sbin
export PATH
skipflash=0

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors

ffversion=` grep -E '\sfirefox\s' /etc/lesslinux/pkglist.txt | awk '{print $3}' ` 

case $1 in 
    start)
	printf "$bold===> Preparing Firefox $ffversion $normal\n"
	for f in /etc/sudoers.lax.d/firefox /etc/sudoers.strict.d/firefox ; do
		sed -i 's/FIREFOXVERSION/'"$ffversion"'/g' ${f} 
		chmod 0440 ${f} 
	done
	[ "$security" '!=' "smack" ] || install -m 0755 /usr/bin/dbus-launch /static/bin/
	mount -t tmpfs -o mode=0755,size=24m,nodev,nosuid tmpfs /opt/firefox-${ffversion}/plugins
	mount --bind /usr/bin/firefox-${ffversion} /usr/bin/firefox
	if [ "$skipflash" -gt 0 ] ; then
	    printf "$bold---> Skipping Flash Player $normal\n"
	elif [ -f /lesslinux/blob/libflashplayer.so ] ; then
	    ln -sf /lesslinux/blob/libflashplayer.so /opt/firefox-${ffversion}/plugins/
	elif [ ` ls /lesslinux/blob/install_flash_player_*.tar.gz 2> /dev/null | wc -l ` -gt 0 ] ; then
	    tar -C  /opt/firefox-${ffversion}/plugins -xvf \
		` ls /lesslinux/blob/install_flash_player_*.tar.gz | tail -n1 ` 
	elif [ -f /usr/lib/browserplugins/libgnashplugin.so ] ; then
	   ln -sf /usr/lib/browserplugins/libgnashplugin.so /opt/firefox-${ffversion}/plugins/
	fi
    ;;
    stop)
	printf "$bold===> Unmounting Firefox overlay $normal\n"
	umount /opt/firefox-${ffversion}/lesslinux > /dev/null 2>&1
	umount /opt/firefox-${ffversion}/plugins > /dev/null 2>&1
	umount /etc/lesslinux/firefox > /dev/null 2>&1
	umount /usr/bin/firefox > /dev/null 2>&1
    ;;
esac

		
