#!/static/bin/ash

# FIXME: Remove dependency on zenity!
# FIXME: Localize!

. /etc/rc.defaults
. /etc/rc.subr/extractbootparams
. /etc/rc.subr/colors
. /etc/rc.lang/en/messages.sh
[ -f "/etc/rc.lang/$lang/messages.sh" ] && . /etc/rc.lang/$lang/messages.sh
. /etc/lesslinux/branding/branding.en.sh
[ -f "/etc/lesslinux/branding/branding.${lang}.sh" ] && . /etc/lesslinux/branding/branding.${lang}.sh

this_version=` cat /etc/lesslinux/updater/version.txt `

/usr/bin/zenity --question --text "$updater_ready_question" || exit 1

# Importiere den Schlüssel
/usr/bin/gpg --import /etc/lesslinux/updater/updatekey.asc

# Update-Ordner erstellen (muss nicht groß sein)
/bin/mkdir -m 0700 /tmp/lesslinux.update

# Download des Update-Scriptes, erfordert setzen de
for fname in updater.tbz updater.tbz.asc ; do
    echo netmgr > /proc/self/attr/current
    /static/bin/wget -O /tmp/lesslinux.update/${fname} http://download.lesslinux.org/updater/${this_version}/${fname}
    retval=$?
    echo _ > /proc/self/attr/current
    if [ "$retval" -gt 0 ] ; then
	/usr/bin/zenity --error --text "$updater_download_failed"
	exit 1
    fi
done

# Prüfung der Signatur
if /usr/bin/gpg --verify /tmp/lesslinux.update/updater.tbz.asc ; then
    echo "===> Signatur OK, fahre fort"
    # Signatur war gut? Na dann starten wir das Script...
    cd /tmp/lesslinux.update
    tar xjf updater.tbz
    /static/bin/ash RUNME.sh
else
    /usr/bin/zenity --error --text "$updater_signature_failed"
    exit 1
fi

		
